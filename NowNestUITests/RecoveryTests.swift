import XCTest

@MainActor
final class RecoveryTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchApp(arguments: [String] = ["-ui-testing", "-visual-variant", "control", "-quiet-mode", "disabled"]) -> XCUIApplication {
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

    // MARK: - Break/Restore: store data loss recovery

    func testAppRecoversAfterDataLossWithPersistentReset() {
        let app = launchApp(arguments: ["-ui-testing-persistent-reset", "-visual-variant", "control", "-quiet-mode", "disabled"])

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Recovery test idea")
        app.buttons["confirmParkButton"].tap()
        XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))
        capture(app, named: "g9-before-data-loss")

        app.terminate()

        let restoredApp = launchApp(arguments: ["-ui-testing-persistent-reset", "-visual-variant", "control", "-quiet-mode", "disabled"])

        XCTAssertTrue(restoredApp.staticTexts["NOW"].waitForExistence(timeout: 10), "App must recover after data loss with persistent reset")
        XCTAssertTrue(restoredApp.staticTexts["Park one real idea"].exists, "Default next action must be present after recovery")

        restoredApp.buttons["Actions"].tap()
        restoredApp.buttons["Review parked ideas"].tap()
        XCTAssertTrue(restoredApp.staticTexts["Nothing parked"].waitForExistence(timeout: 5), "Review must be empty after data loss recovery")
        capture(restoredApp, named: "g9-after-data-loss-recovery")
    }

    // MARK: - Delete/reinstall: fresh state after deletion

    func testAppStartsFreshAfterDeleteAndReinstall() {
        let app = launchApp(arguments: ["-ui-testing-persistent-reset", "-visual-variant", "control", "-quiet-mode", "disabled"])

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Should not survive deletion")
        app.buttons["confirmParkButton"].tap()
        XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))

        app.buttons["Actions"].tap()
        app.buttons["Review parked ideas"].tap()
        XCTAssertTrue(app.staticTexts["Should not survive deletion"].waitForExistence(timeout: 5))
        capture(app, named: "g9-before-deletion")

        app.terminate()

        let reinstalledApp = launchApp(arguments: ["-ui-testing-persistent-reset", "-visual-variant", "control", "-quiet-mode", "disabled"])

        XCTAssertTrue(reinstalledApp.staticTexts["NOW"].waitForExistence(timeout: 10), "App must show NOW after reinstall")
        XCTAssertTrue(reinstalledApp.staticTexts["Park one real idea"].exists, "Default next action must be present after reinstall")

        reinstalledApp.buttons["Actions"].tap()
        reinstalledApp.buttons["Review parked ideas"].tap()
        XCTAssertTrue(reinstalledApp.staticTexts["Nothing parked"].waitForExistence(timeout: 5), "Review must be empty after delete/reinstall")
        capture(reinstalledApp, named: "g9-after-reinstall-fresh")
    }

    // MARK: - Persistence survives graceful relaunch (baseline for recovery)

    func testDataSurvivesGracefulRelaunch() {
        let app = launchApp(arguments: ["-ui-testing-persistent-reset", "-visual-variant", "control", "-quiet-mode", "disabled"])

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Recovery baseline idea")
        app.buttons["confirmParkButton"].tap()
        XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))

        app.terminate()

        let relaunchedApp = launchApp(arguments: ["-ui-testing-persistent", "-visual-variant", "control", "-quiet-mode", "disabled"])
        XCTAssertTrue(relaunchedApp.buttons["Actions"].waitForExistence(timeout: 5))
        relaunchedApp.buttons["Actions"].tap()
        relaunchedApp.buttons["Review parked ideas"].tap()

        XCTAssertTrue(relaunchedApp.staticTexts["Recovery baseline idea"].waitForExistence(timeout: 5), "Parked idea must survive graceful relaunch")
        capture(relaunchedApp, named: "g9-persistence-baseline")
    }

    // MARK: - NOW edit survives relaunch

    func testNowEditSurvivesRelaunch() {
        let app = launchApp(arguments: ["-ui-testing-persistent-reset", "-visual-variant", "control", "-quiet-mode", "disabled"])

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        app.buttons["Actions"].tap()
        app.buttons["Edit NOW"].tap()

        let nextAction = app.textFields.element(boundBy: 2)
        XCTAssertTrue(nextAction.waitForExistence(timeout: 5))
        nextAction.tap()
        nextAction.typeText(" after edit")
        app.buttons["Save"].tap()

        let updatedAction = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "after edit")
        ).firstMatch
        XCTAssertTrue(updatedAction.waitForExistence(timeout: 5))

        app.terminate()

        let relaunchedApp = launchApp(arguments: ["-ui-testing-persistent", "-visual-variant", "control", "-quiet-mode", "disabled"])
        let persistedAction = relaunchedApp.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "after edit")
        ).firstMatch
        XCTAssertTrue(persistedAction.waitForExistence(timeout: 5), "NOW edit must survive relaunch")
        capture(relaunchedApp, named: "g9-now-edit-persisted")
    }
}