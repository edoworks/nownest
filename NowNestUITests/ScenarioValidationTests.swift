import Foundation
import XCTest

@MainActor
final class ScenarioValidationTests: XCTestCase {
    private struct ScenarioContract {
        let id = "competing-context-capture"
        let personaHypothesis = "A founder managing two work contexts may benefit from clear visual hierarchy and a short interruption path."
        let interruption = "Compare standing desks"
        let expectedNextAction = "Save one real idea for later"
        let requiredSteps = ["identify-now", "capture-interruption", "resume-now", "review-saved"]
        let variants = ["control", "expressive", "sophie"]

        func expectedConfirmation(for variant: String) -> String {
            switch variant {
            case "control": return "Saved for later. Back to"
            case "expressive": return "Tucked away. Back to:"
            case "sophie": return "Sophie tucked it away. Back to:"
            default: return ""
            }
        }
    }

    override func setUp() {
        continueAfterFailure = false
    }

    private func launchApp(variant: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-visual-variant", variant,
            "-quiet-mode", "disabled"
        ]
        app.launch()
        return app
    }

    private func recordTrace(
        _ app: XCUIApplication,
        _ contract: ScenarioContract,
        variant: String,
        steps: [String],
        nextActionPreserved: Bool,
        parkedIdeaReviewable: Bool
    ) {
        let payload: [String: Any] = [
            "scenario_id": contract.id,
            "variant": variant,
            "persona_hypothesis": contract.personaHypothesis,
            "steps": steps,
            "next_action_preserved": nextActionPreserved,
            "parked_idea_reviewable": parkedIdeaReviewable,
            "automated_result": "pass",
            "not_proven": [
                "real-user usefulness",
                "accessibility assistive-technology success",
                "willingness to pay",
                "retention"
            ]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
              let trace = String(data: data, encoding: .utf8) else {
            XCTFail("Scenario trace must be valid JSON")
            return
        }
        let attachment = XCTAttachment(string: trace)
        attachment.name = "scenario-\(contract.id)-\(variant)-trace"
        attachment.lifetime = .keepAlways
        add(attachment)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "scenario-\(contract.id)-\(variant)-review"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testCompetingContextsScenarioCompletesAcrossTreatments() {
        let contract = ScenarioContract()

        XCTAssertFalse(contract.personaHypothesis.contains("ADHD"), "Persona hypotheses must not make a clinical claim")
        XCTAssertEqual(contract.requiredSteps.count, 4)

        for variant in contract.variants {
            let app = launchApp(variant: variant)
            var steps: [String] = []

            XCTAssertTrue(app.navigationBars["NowNest"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

            let project = app.staticTexts["PROJECT"]
            let outcome = app.staticTexts["OUTCOME"]
            let nextActionLabel = app.staticTexts["NEXT ACTION"]
            let nextAction = app.staticTexts[contract.expectedNextAction]
            let parkButton = app.buttons["parkIdeaButton"]

            XCTAssertTrue(project.exists)
            XCTAssertTrue(outcome.exists)
            XCTAssertTrue(nextActionLabel.exists)
            XCTAssertTrue(nextAction.exists)
            XCTAssertTrue(parkButton.exists)
            XCTAssertTrue(project.frame.minY > app.staticTexts["NOW"].frame.maxY)
            XCTAssertTrue(outcome.frame.minY > project.frame.maxY)
            XCTAssertTrue(nextActionLabel.frame.minY > outcome.frame.maxY)
            XCTAssertTrue(nextAction.frame.minY > nextActionLabel.frame.maxY)
            XCTAssertTrue(parkButton.frame.minY > nextAction.frame.maxY)
            steps.append("identify-now")

            let originalNextAction = nextAction.label
            parkButton.tap()
            let ideaField = app.textFields["ideaField"]
            XCTAssertTrue(ideaField.waitForExistence(timeout: 5))
            ideaField.typeText(contract.interruption)
            app.buttons["confirmParkButton"].tap()
            let confirmation = app.staticTexts["parkConfirmation"]
            XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
            XCTAssertTrue(
                confirmation.label.contains(contract.expectedConfirmation(for: variant)),
                "Confirmation must prove that the \(variant) treatment was applied"
            )
            let confirmationScreenshot = XCTAttachment(screenshot: app.screenshot())
            confirmationScreenshot.name = "scenario-\(contract.id)-\(variant)-confirmation"
            confirmationScreenshot.lifetime = .keepAlways
            add(confirmationScreenshot)
            steps.append("capture-interruption")

            XCTAssertTrue(app.staticTexts["NOW"].exists)
            let nextActionPreserved = app.staticTexts[contract.expectedNextAction].label == originalNextAction
            XCTAssertTrue(nextActionPreserved)
            steps.append("resume-now")

            let sheetDismissal = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: ideaField
            )
            XCTAssertEqual(
                XCTWaiter.wait(for: [sheetDismissal], timeout: 5),
                .completed,
                "Capture sheet must be dismissed before opening Actions"
            )
            let actionsButton = app.buttons["Actions"]
            XCTAssertTrue(actionsButton.waitForExistence(timeout: 5))
            XCTAssertTrue(actionsButton.isHittable, "Actions must be hittable after the capture sheet is dismissed")
            actionsButton.tap()
            let reviewButton = app.buttons["Review saved ideas"]
            XCTAssertTrue(reviewButton.waitForExistence(timeout: 5))
            XCTAssertTrue(reviewButton.isHittable, "Review must be hittable after opening Actions")
            reviewButton.tap()
            let parkedIdea = app.staticTexts[contract.interruption]
            XCTAssertTrue(parkedIdea.waitForExistence(timeout: 5))
            let parkedIdeaReviewable = parkedIdea.exists && app.staticTexts["READY"].exists
            XCTAssertTrue(parkedIdeaReviewable)
            steps.append("review-saved")

            XCTAssertEqual(steps, contract.requiredSteps)
            recordTrace(
                app,
                contract,
                variant: variant,
                steps: steps,
                nextActionPreserved: nextActionPreserved,
                parkedIdeaReviewable: parkedIdeaReviewable
            )
            app.terminate()
        }
    }
}
