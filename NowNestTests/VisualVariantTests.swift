import XCTest
@testable import NowNest

final class VisualVariantTests: XCTestCase {
    private let nextAction = "Write the first priority"

    func testParsesControlVariant() throws {
        let result = try VisualVariantLaunchParser.parse(
            arguments: ["-visual-variant", "control"],
            failFast: true
        )
        XCTAssertEqual(result.variant, .control)
        XCTAssertNil(result.quietMode)
    }

    func testParsesExpressiveVariant() throws {
        let result = try VisualVariantLaunchParser.parse(
            arguments: ["-visual-variant", "expressive"],
            failFast: true
        )
        XCTAssertEqual(result.variant, .expressive)
    }

    func testParsesSophieVariant() throws {
        let result = try VisualVariantLaunchParser.parse(
            arguments: ["-visual-variant", "sophie"],
            failFast: true
        )
        XCTAssertEqual(result.variant, .sophie)
    }

    func testParsesQuietModeEnabled() throws {
        let result = try VisualVariantLaunchParser.parse(
            arguments: ["-quiet-mode", "enabled"],
            failFast: true
        )
        XCTAssertEqual(result.quietMode, .enabled)
    }

    func testParsesQuietModeDisabled() throws {
        let result = try VisualVariantLaunchParser.parse(
            arguments: ["-quiet-mode", "disabled"],
            failFast: true
        )
        XCTAssertEqual(result.quietMode, .disabled)
    }

    func testParsesBothOptionsTogether() throws {
        let result = try VisualVariantLaunchParser.parse(
            arguments: ["-visual-variant", "sophie", "-quiet-mode", "enabled"],
            failFast: true
        )
        XCTAssertEqual(result.variant, .sophie)
        XCTAssertEqual(result.quietMode, .enabled)
    }

    func testParsesBothOptionsInAnyOrder() throws {
        let result = try VisualVariantLaunchParser.parse(
            arguments: ["-quiet-mode", "disabled", "-visual-variant", "expressive"],
            failFast: true
        )
        XCTAssertEqual(result.variant, .expressive)
        XCTAssertEqual(result.quietMode, .disabled)
    }

    func testMissingVariantValueFailsFastInDebug() {
        XCTAssertThrowsError(
            try VisualVariantLaunchParser.parse(arguments: ["-visual-variant"], failFast: true)
        ) { error in
            XCTAssertEqual(error as? VisualVariantLaunchParser.ParseError, .missingValue(option: "-visual-variant"))
        }
    }

    func testMissingQuietModeValueFailsFastInDebug() {
        XCTAssertThrowsError(
            try VisualVariantLaunchParser.parse(arguments: ["-quiet-mode"], failFast: true)
        ) { error in
            XCTAssertEqual(error as? VisualVariantLaunchParser.ParseError, .missingValue(option: "-quiet-mode"))
        }
    }

    func testUnsupportedVariantValueFailsFastInDebug() {
        XCTAssertThrowsError(
            try VisualVariantLaunchParser.parse(arguments: ["-visual-variant", "bogus"], failFast: true)
        ) { error in
            XCTAssertEqual(
                error as? VisualVariantLaunchParser.ParseError,
                .unsupportedValue(option: "-visual-variant", value: "bogus")
            )
        }
    }

    func testUnsupportedQuietModeValueFailsFastInDebug() {
        XCTAssertThrowsError(
            try VisualVariantLaunchParser.parse(arguments: ["-quiet-mode", "maybe"], failFast: true)
        ) { error in
            XCTAssertEqual(
                error as? VisualVariantLaunchParser.ParseError,
                .unsupportedValue(option: "-quiet-mode", value: "maybe")
            )
        }
    }

    func testDuplicateVariantOptionFailsFastInDebug() {
        XCTAssertThrowsError(
            try VisualVariantLaunchParser.parse(
                arguments: ["-visual-variant", "control", "-visual-variant", "expressive"],
                failFast: true
            )
        ) { error in
            XCTAssertEqual(error as? VisualVariantLaunchParser.ParseError, .duplicateOption(option: "-visual-variant"))
        }
    }

    func testDuplicateQuietModeOptionFailsFastInDebug() {
        XCTAssertThrowsError(
            try VisualVariantLaunchParser.parse(
                arguments: ["-quiet-mode", "enabled", "-quiet-mode", "disabled"],
                failFast: true
            )
        ) { error in
            XCTAssertEqual(error as? VisualVariantLaunchParser.ParseError, .duplicateOption(option: "-quiet-mode"))
        }
    }

    func testReleaseFallbackUsesSophieWhenVariantAbsent() throws {
        let result = try VisualVariantLaunchParser.parse(arguments: [], failFast: false)
        XCTAssertNil(result.variant)
        let config = VisualVariantLaunchParser.resolve(arguments: [], storedQuietMode: false, isDebug: false)
        XCTAssertEqual(config.variant, .sophie)
    }

    func testReleaseFallbackUsesSophieForInvalidVariantValue() throws {
        let config = VisualVariantLaunchParser.resolve(
            arguments: ["-visual-variant", "bogus"],
            storedQuietMode: false,
            isDebug: false
        )
        XCTAssertEqual(config.variant, .sophie)
    }

    func testReleaseIgnoresInvalidQuietModeValue() {
        let config = VisualVariantLaunchParser.resolve(
            arguments: ["-quiet-mode", "maybe"],
            storedQuietMode: true,
            isDebug: false
        )
        XCTAssertEqual(config.quietMode, .enabled)
    }

    func testQuietModeLaunchOverrideDoesNotRequireStoredPreference() {
        let config = VisualVariantLaunchParser.resolve(
            arguments: ["-quiet-mode", "disabled"],
            storedQuietMode: true,
            isDebug: false
        )
        XCTAssertEqual(config.quietMode, .disabled)
    }

    func testQuietModeFallsBackToStoredPreferenceWhenAbsent() {
        let config = VisualVariantLaunchParser.resolve(
            arguments: [],
            storedQuietMode: true,
            isDebug: false
        )
        XCTAssertEqual(config.quietMode, .enabled)
    }

    func testControlConfirmationCopy() {
        let config = VisualVariantConfiguration(variant: .control, quietMode: .disabled)
        XCTAssertEqual(config.confirmationCopy(for: nextAction), "Saved for later. Back to \(nextAction).")
    }

    func testExpressiveConfirmationCopy() {
        let config = VisualVariantConfiguration(variant: .expressive, quietMode: .disabled)
        XCTAssertEqual(config.confirmationCopy(for: nextAction), "Tucked away. Back to: \(nextAction).")
    }

    func testSophieConfirmationCopyWithoutQuietMode() {
        let config = VisualVariantConfiguration(variant: .sophie, quietMode: .disabled)
        XCTAssertEqual(config.confirmationCopy(for: nextAction), "Sophie tucked it away. Back to: \(nextAction).")
    }

    func testSophieConfirmationCopyWithQuietModeUsesExpressiveCopy() {
        let config = VisualVariantConfiguration(variant: .sophie, quietMode: .enabled)
        XCTAssertEqual(config.confirmationCopy(for: nextAction), "Tucked away. Back to: \(nextAction).")
    }

    func testSophieShownOnlyForSophieVariantWithoutQuietMode() {
        XCTAssertTrue(VisualVariantConfiguration(variant: .sophie, quietMode: .disabled).showsSophie)
        XCTAssertFalse(VisualVariantConfiguration(variant: .sophie, quietMode: .enabled).showsSophie)
        XCTAssertFalse(VisualVariantConfiguration(variant: .expressive, quietMode: .disabled).showsSophie)
        XCTAssertFalse(VisualVariantConfiguration(variant: .control, quietMode: .disabled).showsSophie)
    }

    func testNormalizationBehaviorIsUnchanged() {
        XCTAssertEqual(NowNestRules.normalized("  Explore widgets  "), "Explore widgets")
        XCTAssertNil(NowNestRules.normalized("  \n "))
    }

    func testValidNowValuesBehaviorIsUnchanged() {
        let values = NowNestRules.validNowValues(
            project: " Reference App ",
            outcome: " Prove the loop ",
            nextAction: " Dogfood one capture "
        )
        XCTAssertEqual(values?.0, "Reference App")
        XCTAssertEqual(values?.1, "Prove the loop")
        XCTAssertEqual(values?.2, "Dogfood one capture")
    }

    func testParkedIdeaStateRemainsParked() {
        let idea = ParkedIdea(text: "  Compare standing desks  ")
        XCTAssertEqual(idea.state, "PARKED")
        XCTAssertNotNil(idea.id)
        XCTAssertNotNil(idea.createdAt)
    }
}
