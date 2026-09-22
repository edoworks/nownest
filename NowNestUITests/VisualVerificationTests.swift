import XCTest

@MainActor
final class VisualVerificationTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchControl(arguments: [String] = ["-ui-testing", "-visual-variant", "control", "-quiet-mode", "disabled"]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    func testControlVariantLayoutStructureAtLaunch() {
        let app = launchControl()

        XCTAssertTrue(app.navigationBars["NowNest"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let nowLabel = app.staticTexts["NOW"]
        let projectLabel = app.staticTexts["PROJECT"]
        let outcomeLabel = app.staticTexts["OUTCOME"]
        let nextActionLabel = app.staticTexts["NEXT ACTION"]
        let nextActionValue = app.staticTexts["Park one real idea"]
        let parkButton = app.buttons["parkIdeaButton"]

        XCTAssertTrue(projectLabel.exists, "PROJECT label must be visible")
        XCTAssertTrue(outcomeLabel.exists, "OUTCOME label must be visible")
        XCTAssertTrue(nextActionLabel.exists, "NEXT ACTION label must be visible")
        XCTAssertTrue(nextActionValue.exists, "Default next action value must be visible")
        XCTAssertTrue(parkButton.exists, "parkIdeaButton must exist")

        XCTAssertTrue(
            projectLabel.frame.minY > nowLabel.frame.maxY,
            "PROJECT must appear below NOW heading"
        )
        XCTAssertTrue(
            outcomeLabel.frame.minY > projectLabel.frame.maxY,
            "OUTCOME must appear below PROJECT"
        )
        XCTAssertTrue(
            nextActionLabel.frame.minY > outcomeLabel.frame.maxY,
            "NEXT ACTION must appear below OUTCOME"
        )
        XCTAssertTrue(
            nextActionValue.frame.minY > nextActionLabel.frame.maxY,
            "Next action value must appear below NEXT ACTION label"
        )
        XCTAssertTrue(
            parkButton.frame.minY > nextActionValue.frame.maxY,
            "Park button must appear below next action value"
        )

        let parkButtonFrame = parkButton.frame
        XCTAssertGreaterThan(parkButtonFrame.width, 0, "parkIdeaButton must have width")
        XCTAssertGreaterThan(parkButtonFrame.height, 0, "parkIdeaButton must have height")
    }

    func testAccessibilityTreeContentOrder() {
        let app = launchControl()

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let nowHeading = app.staticTexts["NOW"]
        let projectLabel = app.staticTexts["PROJECT"]
        let outcomeLabel = app.staticTexts["OUTCOME"]
        let nextActionLabel = app.staticTexts["NEXT ACTION"]
        let nextActionValue = app.staticTexts["Park one real idea"]
        let parkButton = app.buttons["parkIdeaButton"]

        let elementsInOrder: [(XCUIElement, String)] = [
            (nowHeading, "NOW"),
            (projectLabel, "PROJECT"),
            (outcomeLabel, "OUTCOME"),
            (nextActionLabel, "NEXT ACTION"),
            (nextActionValue, "next action value"),
            (parkButton, "parkIdeaButton"),
        ]

        for i in 1..<elementsInOrder.count {
            let prev = elementsInOrder[i - 1].0.frame
            let curr = elementsInOrder[i].0.frame
            XCTAssertTrue(
                curr.minY >= prev.minY,
                "\(elementsInOrder[i].1) should not appear above \(elementsInOrder[i-1].1) in the layout"
            )
        }
    }

    func testNoHorizontalScrollingRequiredAtDefaultSize() {
        let app = launchControl()

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let nowLabel = app.staticTexts["NOW"]
        let nextActionValue = app.staticTexts["Park one real idea"]
        let parkButton = app.buttons["parkIdeaButton"]

        let window = app.windows.element(boundBy: 0)
        let windowFrame = window.frame

        for (element, name) in [(nowLabel, "NOW"), (nextActionValue, "next action"), (parkButton, "parkIdeaButton")] {
            let frame = element.frame
            XCTAssertLessThanOrEqual(
                frame.maxX,
                windowFrame.maxX,
                "\(name) must not extend beyond window width"
            )
            XCTAssertGreaterThanOrEqual(
                frame.minX,
                windowFrame.minX,
                "\(name) must not start before window"
            )
        }
    }

    func testParkActionIsProminentAndAccessible() {
        let app = launchControl()

        let parkButton = app.buttons["parkIdeaButton"]
        XCTAssertTrue(parkButton.waitForExistence(timeout: 5))

        let parkLabel = parkButton.label
        XCTAssertTrue(parkLabel.contains("Park"), "Park button label must contain 'Park'")
        XCTAssertTrue(parkButton.isEnabled, "Park button must be enabled at launch")

        let nextActionValue = app.staticTexts["Park one real idea"]
        let parkFrame = parkButton.frame
        let nextActionFrame = nextActionValue.frame

        XCTAssertGreaterThanOrEqual(
            parkFrame.width,
            nextActionFrame.width * 0.5,
            "Park button should be at least half the width of the next action text for prominence"
        )
    }

    func testControlVariantLaunchScreenshotRetention() {
        let app = launchControl()

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "control-visual-verification-launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testExpressiveVariantLaunchScreenshotRetention() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-visual-variant", "expressive", "-quiet-mode", "disabled"]
        app.launch()

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "expressive-visual-verification-launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSophieVariantLaunchScreenshotRetention() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-visual-variant", "sophie", "-quiet-mode", "disabled"]
        app.launch()

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "sophie-visual-verification-launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSophieQuietModeLaunchScreenshotRetention() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-visual-variant", "sophie", "-quiet-mode", "enabled"]
        app.launch()

        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "sophie-quiet-visual-verification-launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}