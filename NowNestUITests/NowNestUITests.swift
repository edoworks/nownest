import XCTest

@MainActor
final class NowNestUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        return app
    }

    func testNowIsVisibleAtLaunch() {
        let app = launchApp()

        XCTAssertTrue(app.navigationBars["NowNest"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["parkIdeaButton"].exists)
    }

    func testCaptureReturnsToUnchangedNow() {
        let app = launchApp()
        let nextAction = app.staticTexts["Park one real idea"].label

        app.buttons["parkIdeaButton"].tap()
        let field = app.textFields["ideaField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Explore a later idea")
        app.buttons["confirmParkButton"].tap()

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["Park one real idea"].label, nextAction)
        XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))
    }

    func testReviewShowsOnlyTheIdeaJustParked() {
        let app = launchApp()

        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Review this later")
        app.buttons["confirmParkButton"].tap()

        app.buttons["Actions"].tap()
        app.buttons["Review parked ideas"].tap()

        XCTAssertTrue(app.staticTexts["Review this later"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["PARKED"].exists)
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
    }

    func testReviewDeletionRemovesSelectedIdeaAfterConfirmation() {
        let app = launchApp()

        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Delete this later")
        app.buttons["confirmParkButton"].tap()
        app.buttons["Actions"].tap()
        app.buttons["Review parked ideas"].tap()

        let idea = app.staticTexts["Delete this later"]
        XCTAssertTrue(idea.waitForExistence(timeout: 5))
        idea.swipeLeft()
        app.buttons["Delete"].tap()
        app.buttons["Delete"].tap()

        XCTAssertFalse(idea.waitForExistence(timeout: 2))
    }
}
