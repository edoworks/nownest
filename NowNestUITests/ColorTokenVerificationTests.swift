import XCTest

@MainActor
final class ColorTokenVerificationTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launchControl() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-visual-variant", "control", "-quiet-mode", "disabled"]
        app.launch()
        return app
    }

    func testScreenshotContainsExpectedPaletteColors() {
        let app = launchControl()
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let screenshot = app.screenshot()
        let image = screenshot.image
        let cgImage = image.cgImage

        guard let cgImage else {
            XCTFail("Could not get CGImage from screenshot")
            return
        }

        let width = cgImage.width
        let height = cgImage.height

        XCTAssertGreaterThan(width, 0)
        XCTAssertGreaterThan(height, 0)

        guard let provider = cgImage.dataProvider else {
            XCTFail("Could not get data provider from CGImage")
            return
        }
        guard let data = provider.data else {
            XCTFail("Could not get data from provider")
            return
        }
        let bytes = CFDataGetBytePtr(data)
        XCTAssertNotNil(bytes)

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        let expectedLightCanvas = (r: 0xFF, g: 0xF8, b: 0xEA)
        let expectedLightSurface = (r: 0xFF, g: 0xFD, b: 0xF7)

        var foundCanvasApprox = false
        var foundSurfaceApprox = false

        let tolerance: UInt8 = 20

        let step = 4
        var y = 0
        while y < height {
            var x = 0
            while x < width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                guard offset + 2 < CFDataGetLength(data) else { x += step; continue }

                let r = bytes![offset]
                let g = bytes![offset + 1]
                let b = bytes![offset + 2]

                if abs(Int(r) - Int(expectedLightCanvas.r)) <= Int(tolerance) &&
                   abs(Int(g) - Int(expectedLightCanvas.g)) <= Int(tolerance) &&
                   abs(Int(b) - Int(expectedLightCanvas.b)) <= Int(tolerance) {
                    foundCanvasApprox = true
                }

                if abs(Int(r) - Int(expectedLightSurface.r)) <= Int(tolerance) &&
                   abs(Int(g) - Int(expectedLightSurface.g)) <= Int(tolerance) &&
                   abs(Int(b) - Int(expectedLightSurface.b)) <= Int(tolerance) {
                    foundSurfaceApprox = true
                }

                if foundCanvasApprox && foundSurfaceApprox { break }

                x += step
            }
            if foundCanvasApprox && foundSurfaceApprox { break }
            y += step
        }

        XCTAssertTrue(foundCanvasApprox, "Screenshot must contain canvas-token-range pixels (light #FFF8EA ±\(tolerance))")
        XCTAssertTrue(foundSurfaceApprox, "Screenshot must contain surface-token-range pixels (light #FFFDF7 ±\(tolerance))")
    }

    func testScreenshotIsNotPureSystemBackground() {
        let app = launchControl()
        XCTAssertTrue(app.staticTexts["NOW"].waitForExistence(timeout: 5))

        let screenshot = app.screenshot()
        let image = screenshot.image
        guard let cgImage = image.cgImage,
              let provider = cgImage.dataProvider,
              let data = provider.data else {
            XCTFail("Could not extract pixel data")
            return
        }

        let bytes = CFDataGetBytePtr(data)!
        let bytesPerRow = cgImage.bytesPerRow
        let bytesPerPixel = cgImage.bitsPerPixel / 8

        let width = cgImage.width
        let height = cgImage.height

        let samplePoints: [(Int, Int)] = [
            (width / 4, height / 4),
            (width / 2, height / 8),
            (width * 3 / 4, height / 4),
            (width / 4, height / 2),
            (width * 3 / 4, height / 2),
        ]

        var nonWhite = 0
        var nonBlack = 0
        for (x, y) in samplePoints {
            let offset = y * bytesPerRow + x * bytesPerPixel
            guard offset + 2 < CFDataGetLength(data) else { continue }
            let r = bytes[offset]
            let g = bytes[offset + 1]
            let b = bytes[offset + 2]
            if !(r > 240 && g > 240 && b > 240) { nonWhite += 1 }
            if !(r < 30 && g < 30 && b < 30) { nonBlack += 1 }
        }

        XCTAssertGreaterThan(nonWhite, 0, "At least one sampled pixel must not be pure white system background")
        XCTAssertGreaterThan(nonBlack, 0, "At least one sampled pixel must not be pure black")
    }
}