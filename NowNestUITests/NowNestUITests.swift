import XCTest

@MainActor
final class NowNestUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchApp(arguments: [String] = ["-ui-testing"]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func capture(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testNowIsVisibleAtLaunch() {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["NowNest"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["parkIdeaButton"].exists)
        capture(app, named: "launch-now")
    }

    func testCaptureReturnsToUnchangedNow() {
        let app = launchApp()
        let nextAction = app.staticTexts["Save one real idea for later"].label

        app.buttons["parkIdeaButton"].tap()
        let field = app.textFields["ideaField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Explore a later idea")
        app.buttons["confirmParkButton"].tap()

        XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["Save one real idea for later"].label, nextAction)
        capture(app, named: "capture-confirmed")
    }

    func testReviewShowsOnlyTheIdeaJustParked() {
        let app = launchApp()

        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Review this later")
        app.buttons["confirmParkButton"].tap()

        app.buttons["Actions"].tap()
        app.buttons["Review saved ideas"].tap()

        XCTAssertTrue(app.staticTexts["Review this later"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["READY"].exists)
        capture(app, named: "review-parked")
    }

    func testParkedIdeaSurvivesAppRelaunch() {
        let app = launchApp(arguments: ["-ui-testing-persistent-reset"])

        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Relaunch survivor")
        app.buttons["confirmParkButton"].tap()
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 10))
        capture(app, named: "persistence-parked")

        app.terminate()

        let relaunchedApp = launchApp(arguments: ["-ui-testing-persistent"])
        XCTAssertTrue(relaunchedApp.buttons["Actions"].waitForExistence(timeout: 5))
        relaunchedApp.buttons["Actions"].tap()
        relaunchedApp.buttons["Review saved ideas"].tap()

        XCTAssertTrue(relaunchedApp.staticTexts["Relaunch survivor"].waitForExistence(timeout: 5))
        XCTAssertTrue(relaunchedApp.staticTexts["READY"].exists)
        capture(relaunchedApp, named: "persistence-relaunch")
    }

    func testPriorBuildStoreMigratesWithoutLosingParkedIdea() {
        let app = launchApp(arguments: ["-ui-testing-persistent"])
        XCTAssertTrue(app.buttons["Actions"].waitForExistence(timeout: 5))
        app.buttons["reviewParkedButton"].tap()
        XCTAssertTrue(app.staticTexts["Relaunch survivor"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["READY"].exists)
    }

    func testExplicitNowEditChangesOnlyAfterSave() {
        let app = launchApp()

        app.buttons["Actions"].tap()
        app.buttons["Edit NOW"].tap()

        let nextAction = app.textFields.element(boundBy: 2)
        XCTAssertTrue(nextAction.waitForExistence(timeout: 5))
        nextAction.tap()
        nextAction.typeText(" and return")
        app.buttons["Save"].tap()

        let updatedAction = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "and return")
        ).firstMatch
        XCTAssertTrue(updatedAction.waitForExistence(timeout: 5))
        capture(app, named: "now-edited")
    }

    func testReviewAbandonRemovesSelectedIdea() {
        let app = launchApp()

        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Delete this later")
        app.buttons["confirmParkButton"].tap()
        app.buttons["Actions"].tap()
        app.buttons["Review saved ideas"].tap()

        let idea = app.staticTexts["Delete this later"]
        XCTAssertTrue(idea.waitForExistence(timeout: 5))
        idea.swipeLeft()
        app.buttons["Abandon"].tap()

        XCTAssertFalse(idea.waitForExistence(timeout: 2))
        capture(app, named: "review-deleted")
    }

    func testParkedIdeaCanResumeAndResolve() {
        let app = launchApp(arguments: ["-ui-testing-persistent-reset"])

        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Investigate Foundation Models")
        app.buttons["confirmParkButton"].tap()
        app.terminate()

        let relaunchedApp = launchApp(arguments: ["-ui-testing-persistent"])
        relaunchedApp.buttons["reviewParkedButton"].tap()
        relaunchedApp.staticTexts["Investigate Foundation Models"].tap()

        XCTAssertTrue(relaunchedApp.staticTexts["originalThought"].waitForExistence(timeout: 5))
        XCTAssertTrue(relaunchedApp.staticTexts["You were doing"].exists)
        relaunchedApp.buttons["resumeIdeaButton"].tap()

        XCTAssertTrue(relaunchedApp.buttons["completeActiveButton"].waitForExistence(timeout: 5))
        relaunchedApp.buttons["completeActiveButton"].tap()
        XCTAssertTrue(relaunchedApp.staticTexts["Save one real idea for later"].waitForExistence(timeout: 5))
        capture(relaunchedApp, named: "resume-complete")
    }
}
