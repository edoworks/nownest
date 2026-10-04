import XCTest

@MainActor
final class DeferredReviewUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(mode: String = "ready", persistent: String? = nil, large: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [persistent ?? "-ui-testing", "-review-mode", mode,
                               "-suggestion-mode", "unavailable", "-visual-variant", "control"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }

    private func save(_ text: String, app: XCUIApplication) {
        XCTAssertTrue(app.buttons["parkIdeaButton"].waitForExistence(timeout: 10))
        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText(text)
        app.buttons["confirmParkButton"].tap()
        XCTAssertTrue(app.buttons["reviewParkedButton"].waitForExistence(timeout: 5))
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "1"),
            object: app.buttons["reviewParkedButton"]
        )], timeout: 5), .completed)
        XCTAssertTrue(app.staticTexts["NOW"].exists)
    }

    private func open(_ text: String, app: XCUIApplication) {
        app.buttons["reviewParkedButton"].tap()
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5))
        app.staticTexts[text].tap()
        XCTAssertTrue(app.staticTexts["originalThought"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["originalThought"].label, text)
    }

    private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<10 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists)
        XCTAssertTrue(element.isHittable)
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testAutomaticSummaryRetainsOriginalAndKeepDoesNotResume() {
        let app = launch()
        save("Review this without changing NOW", app: app)
        open("Review this without changing NOW", app: app)
        reveal(app.staticTexts["reviewCategory"], app: app)
        XCTAssertEqual(app.staticTexts["reviewCategory"].label, "Needs clarification")
        XCTAssertTrue(app.staticTexts["reviewUncertainty"].exists)
        capture(app, name: "automatic-review-summary")
        reveal(app.buttons["keepIdeaButton"], app: app)
        app.buttons["keepIdeaButton"].tap()
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Kept for later"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Save one real idea for later"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reviewParkedButton"].label.contains("1"))
    }

    func testUnavailableAllowsManualKeep() {
        let app = launch(mode: "unavailable")
        save("Manual choice remains available", app: app)
        open("Manual choice remains available", app: app)
        reveal(app.staticTexts["reviewStatus"], app: app)
        XCTAssertEqual(app.staticTexts["reviewStatus"].label, "On-device review unavailable")
        reveal(app.buttons["keepIdeaButton"], app: app)
        app.buttons["keepIdeaButton"].tap()
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Kept for later"].waitForExistence(timeout: 5))
        capture(app, name: "manual-fallback-kept")
    }

    func testFailureOffersRetryAndRetainsOriginal() {
        let app = launch(mode: "failure")
        save("Failure must not remove this", app: app)
        open("Failure must not remove this", app: app)
        reveal(app.buttons["retryReviewButton"], app: app)
        app.buttons["retryReviewButton"].tap()
        XCTAssertTrue(app.staticTexts["reviewStatus"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reviewStatus"].label, "Review couldn’t finish")
        XCTAssertFalse(app.staticTexts["reviewCategory"].exists)
        capture(app, name: "review-failed-retry")
    }

    func testDiscardRequiresConfirmation() {
        let app = launch()
        save("A decision only I can make", app: app)
        open("A decision only I can make", app: app)
        reveal(app.buttons["discardIdeaButton"], app: app)
        app.buttons["discardIdeaButton"].tap()
        let dialog = app.alerts["Discard this idea?"]
        XCTAssertTrue(dialog.waitForExistence(timeout: 5))
        capture(app, name: "discard-confirmation")
        dialog.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(app.buttons["discardIdeaButton"].exists)
        app.buttons["discardIdeaButton"].tap()
        dialog.buttons["Discard idea"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Nothing saved"].waitForExistence(timeout: 5))
    }

    func testSummarySurvivesRelaunchWithoutCallingFailingModel() {
        var app = launch(persistent: "-ui-testing-persistent-reset")
        save("Persist this decision summary", app: app)
        open("Persist this decision summary", app: app)
        reveal(app.staticTexts["reviewCategory"], app: app)
        app.terminate()
        app = launch(mode: "failure", persistent: "-ui-testing-persistent")
        open("Persist this decision summary", app: app)
        reveal(app.staticTexts["reviewCategory"], app: app)
        XCTAssertEqual(app.staticTexts["reviewCategory"].label, "Needs clarification")
        capture(app, name: "review-persisted-after-relaunch")
    }

    func testInterruptedReviewIsRecoverableAfterRelaunch() {
        var app = launch(mode: "delayed", persistent: "-ui-testing-persistent-reset")
        save("Interrupted review survivor", app: app)
        open("Interrupted review survivor", app: app)
        reveal(app.staticTexts["reviewProcessingState"], app: app)
        app.terminate()
        app = launch(persistent: "-ui-testing-persistent")
        open("Interrupted review survivor", app: app)
        reveal(app.staticTexts["reviewStatus"], app: app)
        XCTAssertEqual(app.staticTexts["reviewStatus"].label, "Review paused")
        reveal(app.buttons["retryReviewButton"], app: app)
        app.buttons["retryReviewButton"].tap()
        XCTAssertTrue(app.staticTexts["reviewCategory"].waitForExistence(timeout: 5))
    }

    func testLargeTextKeepsDecisionsReachable() {
        let app = launch(large: true)
        save("A short idea", app: app)
        open("A short idea", app: app)
        reveal(app.staticTexts["reviewCategory"], app: app)
        capture(app, name: "review-accessibility-text")
        reveal(app.buttons["keepIdeaButton"], app: app)
        app.buttons["keepIdeaButton"].tap()
        // No lifecycle change; the action only acknowledges the review.
        XCTAssertFalse(app.buttons["keepIdeaButton"].exists)
        reveal(app.buttons["addUpdateButton"], app: app)
        app.buttons["addUpdateButton"].tap()
        XCTAssertTrue(app.navigationBars["Add update"].exists)
        XCTAssertTrue(app.buttons["saveUpdateButton"].exists)
        capture(app, name: "add-update-accessibility-text")
    }

    func testAddUpdateCanCancelAndRequiresText() {
        let app = launch()
        save("Original idea stays here", app: app)
        open("Original idea stays here", app: app)
        reveal(app.buttons["addUpdateButton"], app: app)
        app.buttons["addUpdateButton"].tap()
        XCTAssertFalse(app.buttons["saveUpdateButton"].isEnabled)
        capture(app, name: "add-update-sheet")
        app.textFields["ideaUpdateField"].tap()
        app.textFields["ideaUpdateField"].typeText("Draft that should not save")
        app.navigationBars["Add update"].buttons["Cancel"].tap()
        XCTAssertFalse(app.buttons["savedUpdates"].exists)
        XCTAssertEqual(app.staticTexts["originalThought"].label, "Original idea stays here")
        reveal(app.staticTexts["reviewCategory"], app: app)
        XCTAssertEqual(app.staticTexts["reviewCategory"].label, "Needs clarification")
    }

    func testSavedUpdateCreatesFreshReviewAndPreservesEarlierResult() {
        let app = launch()
        save("Keep this original intact", app: app)
        open("Keep this original intact", app: app)
        reveal(app.staticTexts["reviewCategory"], app: app)
        reveal(app.buttons["addUpdateButton"], app: app)
        app.buttons["addUpdateButton"].tap()
        app.textFields["ideaUpdateField"].tap()
        app.textFields["ideaUpdateField"].typeText("New information changes the effort")
        app.buttons["saveUpdateButton"].tap()
        reveal(app.staticTexts["reviewCategory"], app: app)
        XCTAssertEqual(app.staticTexts["originalThought"].label, "Keep this original intact")
        XCTAssertTrue(app.buttons["savedUpdates"].exists)
        XCTAssertTrue(app.buttons["Earlier reviews (1)"].exists)
        reveal(app.buttons["keepIdeaButton"], app: app)
        XCTAssertTrue(app.buttons["discardIdeaButton"].exists)
        app.buttons["keepIdeaButton"].tap()
        XCTAssertTrue(app.staticTexts["reviewKeptState"].exists)
    }

    func testUpdateSavedAndPreviousReviewVisibleDuringProcessingAndAfterRelaunch() {
        var app = launch(mode: "update-delayed", persistent: "-ui-testing-persistent-reset")
        save("Original with a follow-up", app: app)
        open("Original with a follow-up", app: app)
        reveal(app.staticTexts["reviewCategory"], app: app)
        reveal(app.buttons["addUpdateButton"], app: app)
        app.buttons["addUpdateButton"].tap()
        app.textFields["ideaUpdateField"].tap()
        app.textFields["ideaUpdateField"].typeText("A constraint arrived later")
        app.buttons["saveUpdateButton"].tap()
        reveal(app.staticTexts["previousReview"], app: app)
        XCTAssertTrue(app.staticTexts["updateSavedState"].exists)
        XCTAssertFalse(app.staticTexts["reviewCategory"].exists)
        capture(app, name: "saved-update-previous-review")
        app.terminate()
        app = launch(mode: "ready", persistent: "-ui-testing-persistent")
        open("Original with a follow-up", app: app)
        reveal(app.staticTexts["previousReview"], app: app)
        XCTAssertTrue(app.staticTexts["reviewStatus"].exists)
        reveal(app.buttons["retryReviewButton"], app: app)
        app.buttons["retryReviewButton"].tap()
        XCTAssertTrue(app.staticTexts["reviewCategory"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["savedUpdates"].exists)
    }
}

@MainActor
extension DeferredReviewUITests {
    func testBackgroundPausesReviewAndForegroundDoesNotSilentlyRetry() {
        let app = launch(mode: "delayed")
        save("Pause when I leave the app", app: app)
        open("Pause when I leave the app", app: app)
        reveal(app.staticTexts["reviewProcessingState"], app: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["reviewStatus"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reviewStatus"].label, "Review paused")
        XCTAssertFalse(app.staticTexts["reviewCategory"].exists)
    }
}
