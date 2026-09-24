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

    private func saveAndOpenIdea(_ text: String, in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["parkIdeaButton"].waitForExistence(timeout: 5))
        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText(text)
        app.buttons["confirmParkButton"].tap()
        XCTAssertTrue(app.buttons["reviewParkedButton"].waitForExistence(timeout: 5))
        app.buttons["reviewParkedButton"].tap()
        let idea = app.staticTexts[text]
        XCTAssertTrue(idea.waitForExistence(timeout: 5))
        idea.tap()
        XCTAssertTrue(app.textFields["startingActionField"].waitForExistence(timeout: 5))
    }

    private func editText(in field: XCUIElement, adding text: String) {
        field.tap()
        field.typeText(text)
        XCTAssertTrue((field.value as? String)?.contains(text) == true)
    }

    private func tapResume(in app: XCUIApplication) {
        let button = app.buttons["resumeIdeaButton"]
        for _ in 0..<3 where !button.exists {
            app.swipeUp()
        }
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
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
        XCTAssertTrue(app.staticTexts["SAVED"].exists)
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
        XCTAssertTrue(relaunchedApp.staticTexts["SAVED"].exists)
        capture(relaunchedApp, named: "persistence-relaunch")
    }

    func testPriorBuildStoreMigratesWithoutLosingParkedIdea() {
        let app = launchApp(arguments: ["-ui-testing-persistent"])
        XCTAssertTrue(app.buttons["Actions"].waitForExistence(timeout: 5))
        app.buttons["reviewParkedButton"].tap()
        XCTAssertTrue(app.staticTexts["Relaunch survivor"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["SAVED"].exists)
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
        tapResume(in: relaunchedApp)

        XCTAssertTrue(relaunchedApp.buttons["completeActiveButton"].waitForExistence(timeout: 5))
        relaunchedApp.buttons["completeActiveButton"].tap()
        XCTAssertTrue(relaunchedApp.staticTexts["Save one real idea for later"].waitForExistence(timeout: 5))
        capture(relaunchedApp, named: "resume-complete")
    }

    func testSuggestionReadyCanBeEditedBeforeResume() {
        let app = launchApp(arguments: ["-ui-testing", "-suggestion-mode", "ready"])
        saveAndOpenIdea("Investigate local models", in: app)

        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionReadyState"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["suggestionReadyLabel"].exists)

        let field = app.textFields["startingActionField"]
        XCTAssertEqual(field.value as? String, "Open the Foundation Models documentation and read the overview.")
        editText(in: field, adding: "Edited action")
        tapResume(in: app)

        XCTAssertTrue(app.staticTexts["nextaction"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["nextaction"].label.contains("Edited action"))
    }

    func testUnavailableSuggestionKeepsManualResumeUsable() {
        let app = launchApp(arguments: ["-ui-testing", "-suggestion-mode", "unavailable"])
        saveAndOpenIdea("Compare standing desks", in: app)

        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionUnavailableState"].waitForExistence(timeout: 5))
        let field = app.textFields["startingActionField"]
        editText(in: field, adding: "Manual action")
        tapResume(in: app)

        XCTAssertTrue(app.staticTexts["nextaction"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["nextaction"].label.contains("Manual action"))
    }

    func testFailedSuggestionKeepsManualResumeUsable() {
        let app = launchApp(arguments: ["-ui-testing", "-suggestion-mode", "failure"])
        saveAndOpenIdea("Draft a customer question", in: app)

        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionFailedState"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["retrySuggestionButton"].exists)
        let field = app.textFields["startingActionField"]
        editText(in: field, adding: "Manual fallback")
        tapResume(in: app)

        XCTAssertTrue(app.staticTexts["nextaction"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["nextaction"].label.contains("Manual fallback"))
    }

    func testMalformedSuggestionKeepsManualResumeUsable() {
        let app = launchApp(arguments: ["-ui-testing", "-suggestion-mode", "malformed"])
        saveAndOpenIdea("Outline the release note", in: app)

        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionFailedState"].waitForExistence(timeout: 5))
        let field = app.textFields["startingActionField"]
        XCTAssertEqual(field.value as? String, "Outline the release note")
        editText(in: field, adding: "Manual fallback")
        tapResume(in: app)

        XCTAssertTrue(app.staticTexts["nextaction"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["nextaction"].label.contains("Manual fallback"))
    }

    func testDelayedSuggestionDoesNotOverwriteManualEdit() {
        let app = launchApp(arguments: ["-ui-testing", "-suggestion-mode", "delayed-ready"])
        saveAndOpenIdea("Keep the saved thought", in: app)

        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionPreparingState"].waitForExistence(timeout: 5))
        let field = app.textFields["startingActionField"]
        field.tap()
        field.typeText("Manual edit wins")

        XCTAssertTrue(app.staticTexts["suggestionSavedState"].waitForExistence(timeout: 5))
        XCTAssertTrue((field.value as? String)?.contains("Manual edit wins") == true)
        XCTAssertFalse((field.value as? String)?.contains("Generated action") == true)
    }

    func testUnresumedSuggestionIsNotPersistedAndManualRelaunchStillWorks() {
        let app = launchApp(arguments: ["-ui-testing-persistent-reset", "-suggestion-mode", "ready"])
        saveAndOpenIdea("Preserve this saved thought", in: app)
        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionReadyState"].waitForExistence(timeout: 5))
        app.terminate()

        let relaunchedApp = launchApp(arguments: ["-ui-testing-persistent", "-suggestion-mode", "unavailable"])
        relaunchedApp.buttons["reviewParkedButton"].tap()
        XCTAssertTrue(relaunchedApp.staticTexts["Preserve this saved thought"].waitForExistence(timeout: 5))
        relaunchedApp.staticTexts["Preserve this saved thought"].tap()
        let field = relaunchedApp.textFields["startingActionField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, "Preserve this saved thought")
        XCTAssertTrue(relaunchedApp.staticTexts["suggestionSavedState"].exists)
        editText(in: field, adding: "Relaunch edit")
        tapResume(in: relaunchedApp)

        XCTAssertTrue(relaunchedApp.staticTexts["nextaction"].waitForExistence(timeout: 5))
        XCTAssertTrue(relaunchedApp.staticTexts["nextaction"].label.contains("Relaunch edit"))
    }
}
