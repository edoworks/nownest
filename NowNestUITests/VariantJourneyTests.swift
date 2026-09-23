import XCTest

@MainActor
final class VariantJourneyTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchApp(variant: String, quietMode: String = "disabled", extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        var args = ["-visual-variant", variant, "-quiet-mode", quietMode]
        if !extraArgs.contains("-ui-testing-persistent-reset") && !extraArgs.contains("-ui-testing-persistent") {
            args.append("-ui-testing")
        }
        args.append(contentsOf: extraArgs)
        app.launchArguments = args
        app.launch()
        return app
    }

    private func capture(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Launch tests for each variant

    func testControlVariantLaunchNow() {
        let app = launchApp(variant: "control")
        XCTAssertTrue(app.navigationBars["NowNest"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["parkIdeaButton"].exists)
        capture(app, named: "control-launch-now")
    }

    func testExpressiveVariantLaunchNow() {
        let app = launchApp(variant: "expressive")
        XCTAssertTrue(app.navigationBars["NowNest"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["parkIdeaButton"].exists)
        capture(app, named: "expressive-launch-now")
    }

    func testSophieVariantLaunchNow() {
        let app = launchApp(variant: "sophie")
        XCTAssertTrue(app.navigationBars["NowNest"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["parkIdeaButton"].exists)
        capture(app, named: "sophie-launch-now")
    }

    // MARK: - Capture + unchanged NOW for each variant

    func testControlVariantCaptureReturnsToUnchangedNow() {
        let app = launchApp(variant: "control")
        let nextAction = app.staticTexts["Save one real idea for later"].label

        app.buttons["parkIdeaButton"].tap()
        let field = app.textFields["ideaField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Explore a later idea")
        app.buttons["confirmParkButton"].tap()

        XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["Save one real idea for later"].label, nextAction)
        capture(app, named: "control-capture-confirmed")
    }

    func testExpressiveVariantCaptureReturnsToUnchangedNow() {
        let app = launchApp(variant: "expressive")
        let nextAction = app.staticTexts["Save one real idea for later"].label

        app.buttons["parkIdeaButton"].tap()
        let field = app.textFields["ideaField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Explore a later idea")
        app.buttons["confirmParkButton"].tap()

        XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["Save one real idea for later"].label, nextAction)
        capture(app, named: "expressive-capture-confirmed")
    }

    func testSophieVariantCaptureReturnsToUnchangedNow() {
        let app = launchApp(variant: "sophie")
        let nextAction = app.staticTexts["Save one real idea for later"].label

        app.buttons["parkIdeaButton"].tap()
        let field = app.textFields["ideaField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Explore a later idea")
        app.buttons["confirmParkButton"].tap()

        XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["Save one real idea for later"].label, nextAction)
        capture(app, named: "sophie-capture-confirmed")
    }

    // MARK: - Sophie Quiet Mode test

    func testSophieQuietModeAppliesImmediately() {
        let app = launchApp(variant: "sophie", quietMode: "disabled")
        let reassurance = app.staticTexts["Capture it safely, then return here. Nothing changes NOW unless you edit it."]

        XCTAssertTrue(reassurance.waitForExistence(timeout: 5))
        app.buttons["Actions"].tap()
        let quietMode = app.descendants(matching: .any)["quietModeToggle"]
        XCTAssertTrue(quietMode.waitForExistence(timeout: 5))
        quietMode.tap()

        XCTAssertFalse(reassurance.waitForExistence(timeout: 2))
        app.buttons["Actions"].tap()
        app.buttons["Review saved ideas"].tap()
        XCTAssertTrue(app.staticTexts["Nothing saved"].waitForExistence(timeout: 5))
        capture(app, named: "sophie-quiet-mode-immediate")
    }

    func testSophieQuietModeRemovesSophieWithoutRemovingControls() {
        let app = launchApp(variant: "sophie", quietMode: "enabled")

        XCTAssertTrue(app.navigationBars["NowNest"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["parkIdeaButton"].exists)

        let nextAction = app.staticTexts["Save one real idea for later"].label

        app.buttons["parkIdeaButton"].tap()
        let field = app.textFields["ideaField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Quiet mode test idea")
        app.buttons["confirmParkButton"].tap()

        XCTAssertTrue(app.staticTexts["parkConfirmation"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["Save one real idea for later"].label, nextAction)

        app.buttons["Actions"].tap()
        app.buttons["Review saved ideas"].tap()
        XCTAssertTrue(app.staticTexts["Quiet mode test idea"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["READY"].exists)

        capture(app, named: "sophie-quiet-mode-verified")
    }

    // MARK: - Persistence across variants

    func testExpressiveVariantParkedIdeaSurvivesAppRelaunch() {
        let app = launchApp(variant: "expressive", quietMode: "disabled", extraArgs: ["-ui-testing-persistent-reset"])

        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Expressive relaunch survivor")
        app.buttons["confirmParkButton"].tap()
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 10))

        app.terminate()

        let relaunchedApp = launchApp(variant: "expressive", quietMode: "disabled", extraArgs: ["-ui-testing-persistent"])
        XCTAssertTrue(relaunchedApp.buttons["Actions"].waitForExistence(timeout: 5))
        relaunchedApp.buttons["Actions"].tap()
        relaunchedApp.buttons["Review saved ideas"].tap()

        XCTAssertTrue(relaunchedApp.staticTexts["Expressive relaunch survivor"].waitForExistence(timeout: 5))
        XCTAssertTrue(relaunchedApp.staticTexts["READY"].exists)
    }

    func testSophieVariantParkedIdeaSurvivesAppRelaunch() {
        let app = launchApp(variant: "sophie", quietMode: "disabled", extraArgs: ["-ui-testing-persistent-reset"])

        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Sophie relaunch survivor")
        app.buttons["confirmParkButton"].tap()
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 10))

        app.terminate()

        let relaunchedApp = launchApp(variant: "sophie", quietMode: "disabled", extraArgs: ["-ui-testing-persistent"])
        XCTAssertTrue(relaunchedApp.buttons["Actions"].waitForExistence(timeout: 5))
        relaunchedApp.buttons["Actions"].tap()
        relaunchedApp.buttons["Review saved ideas"].tap()

        XCTAssertTrue(relaunchedApp.staticTexts["Sophie relaunch survivor"].waitForExistence(timeout: 5))
        XCTAssertTrue(relaunchedApp.staticTexts["READY"].exists)
    }
}
