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

    private func openSuggestionDetail(
        mode: String,
        additionalArguments: [String] = []
    ) -> XCUIApplication {
        let app = launchControl(arguments: [
            "-ui-testing",
            "-visual-variant", "control",
            "-quiet-mode", "disabled",
            "-suggestion-mode", mode
        ] + additionalArguments)
        XCTAssertTrue(app.buttons["parkIdeaButton"].waitForExistence(timeout: 5))
        app.buttons["parkIdeaButton"].tap()
        app.textFields["ideaField"].typeText("Compare standing desks")
        app.buttons["confirmParkButton"].tap()
        app.buttons["reviewParkedButton"].tap()
        XCTAssertTrue(app.staticTexts["Compare standing desks"].waitForExistence(timeout: 5))
        app.staticTexts["Compare standing desks"].tap()
        XCTAssertTrue(app.buttons["requestSuggestionButton"].waitForExistence(timeout: 5))
        return app
    }

    private func revealSuggestionControls(_ app: XCUIApplication, stateIdentifier: String) {
        let state = app.staticTexts[stateIdentifier]
        let field = app.textFields["startingActionField"]
        let resume = app.buttons["resumeIdeaButton"]
        for _ in 0..<3 where !resume.exists {
            app.swipeUp()
        }

        XCTAssertTrue(state.exists)
        XCTAssertTrue(field.exists)
        XCTAssertTrue(resume.waitForExistence(timeout: 5))
        XCTAssertTrue(app.frame.contains(state.frame))
        XCTAssertTrue(app.frame.contains(field.frame))
        XCTAssertTrue(app.frame.contains(resume.frame))
    }

    private func retainScreenshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testControlVariantLayoutStructureAtLaunch() {
        let app = launchControl()

        XCTAssertTrue(app.navigationBars["NowNest"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let nowLabel = app.staticTexts["NOW"]
        let projectLabel = app.staticTexts["PROJECT"]
        let outcomeLabel = app.staticTexts["OUTCOME"]
        let nextActionLabel = app.staticTexts["NEXT ACTION"]
        let nextActionValue = app.staticTexts["Save one real idea for later"]
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
        let nextActionValue = app.staticTexts["Save one real idea for later"]
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
        let nextActionValue = app.staticTexts["Save one real idea for later"]
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
        XCTAssertTrue(parkLabel.contains("Save for later"), "Primary button must use plain-language Save for later copy")
        XCTAssertTrue(parkButton.isEnabled, "Park button must be enabled at launch")

        let nextActionValue = app.staticTexts["Save one real idea for later"]
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

    func testPrimaryActionDarkModeScreenshotRetention() {
        let app = launchControl(arguments: [
            "-ui-testing",
            "-ui-testing-dark-mode",
            "-visual-variant", "sophie",
            "-quiet-mode", "disabled"
        ])

        XCTAssertTrue(app.buttons["parkIdeaButton"].waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "primary-action-dark-mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSuggestionPreparingScreenshotRetention() {
        let app = openSuggestionDetail(mode: "preparing")
        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionPreparingState"].waitForExistence(timeout: 5))
        revealSuggestionControls(app, stateIdentifier: "suggestionPreparingState")
        retainScreenshot(app, named: "suggestion-preparing")
    }

    func testSuggestionReadyScreenshotRetention() {
        let app = openSuggestionDetail(mode: "ready")
        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionReadyState"].waitForExistence(timeout: 5))
        revealSuggestionControls(app, stateIdentifier: "suggestionReadyState")
        retainScreenshot(app, named: "suggestion-ready")
    }

    func testSuggestionUnavailableScreenshotRetention() {
        let app = openSuggestionDetail(mode: "unavailable")
        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionUnavailableState"].waitForExistence(timeout: 5))
        revealSuggestionControls(app, stateIdentifier: "suggestionUnavailableState")
        retainScreenshot(app, named: "suggestion-unavailable")
    }

    func testSuggestionReadyAtLargestAccessibilityTextSize() {
        let app = openSuggestionDetail(
            mode: "ready",
            additionalArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
            ]
        )
        app.buttons["requestSuggestionButton"].tap()
        XCTAssertTrue(app.staticTexts["suggestionReadyState"].waitForExistence(timeout: 5))
        revealSuggestionControls(app, stateIdentifier: "suggestionReadyState")
        retainScreenshot(app, named: "suggestion-ready-accessibility-text")
    }
}
