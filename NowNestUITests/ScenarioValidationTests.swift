import XCTest

@MainActor
final class ScenarioValidationTests: XCTestCase {
    private struct ScenarioContract {
        let id = "competing-context-capture"
        let personaHypothesis = "A founder managing two work contexts may benefit from clear visual hierarchy and a short interruption path."
        let interruption = "Compare standing desks"
        let expectedNextAction = "Park one real idea"
        let requiredSteps = ["identify-now", "capture-interruption", "resume-now", "review-parked"]
        let variants = ["control", "expressive", "sophie"]
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
        let trace = """
        {
          "scenario_id": "\(contract.id)",
          "variant": "\(variant)",
          "persona_hypothesis": "\(contract.personaHypothesis)",
          "steps": ["\(steps.joined(separator: "\", \""))"],
          "next_action_preserved": \(nextActionPreserved),
          "parked_idea_reviewable": \(parkedIdeaReviewable),
          "automated_result": "pass",
          "not_proven": ["real-user usefulness", "accessibility assistive-technology success", "willingness to pay", "retention"]
        }
        """
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
            XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))
            steps.append("capture-interruption")

            XCTAssertTrue(app.staticTexts["NOW"].exists)
            XCTAssertEqual(app.staticTexts[contract.expectedNextAction].label, originalNextAction)
            steps.append("resume-now")

            app.buttons["Actions"].tap()
            app.buttons["Review parked ideas"].tap()
            XCTAssertTrue(app.staticTexts[contract.interruption].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["PARKED"].exists)
            steps.append("review-parked")

            XCTAssertEqual(steps, contract.requiredSteps)
            recordTrace(
                app,
                contract,
                variant: variant,
                steps: steps,
                nextActionPreserved: true,
                parkedIdeaReviewable: true
            )
            app.terminate()
        }
    }
}
