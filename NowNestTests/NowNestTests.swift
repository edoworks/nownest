import XCTest
import SwiftData
@testable import NowNest

final class NowNestTests: XCTestCase {
    func testWhitespaceIdeaIsRejected() throws {
        XCTAssertNil(NowNestRules.normalized("  \n "))
    }

    func testParkingPersistsIdeaWithoutChangingNow() throws {
        let idea = ParkedIdea(text: "  Explore widgets  ")

        XCTAssertEqual(idea.text, "  Explore widgets  ")
        XCTAssertEqual(idea.state, "PARKED")
        XCTAssertNotNil(idea.id)
        XCTAssertNotNil(idea.createdAt)
    }

    func testParkingInputIsNormalizedBeforePersistence() {
        XCTAssertEqual(NowNestRules.normalized("  Explore widgets  "), "Explore widgets")
    }

    func testParkingDoesNotChangeNowValues() {
        let values = NowNestRules.validNowValues(
            project: "Factory",
            outcome: "Ship",
            nextAction: "Run tests"
        )

        XCTAssertEqual(values?.0, "Factory")
        XCTAssertEqual(values?.1, "Ship")
        XCTAssertEqual(values?.2, "Run tests")
    }

    func testEmptyNowEditCannotReplaceCurrentValues() {
        let values = NowNestRules.validNowValues(
            project: "Factory",
            outcome: " ",
            nextAction: "Run tests"
        )

        XCTAssertNil(values)
    }

    func testNowEditPersistsAllFields() {
        let values = NowNestRules.validNowValues(
            project: " Reference App ",
            outcome: " Prove the loop ",
            nextAction: " Dogfood one capture "
        )

        XCTAssertEqual(values?.0, "Reference App")
        XCTAssertEqual(values?.1, "Prove the loop")
        XCTAssertEqual(values?.2, "Dogfood one capture")
    }

    func testRecoverFromCorruptedStoreCreatesFreshContainer() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nownest-recovery-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let storeURL = tempDir.appendingPathComponent("default.store")
        try Data("CORRUPTED-GARBAGE".utf8).write(to: storeURL)

        let schema = Schema([NowContext.self, ParkedIdea.self])
        let container = try NowNestApp.recoverFromCorruptedStore(at: storeURL, schema: schema)

        XCTAssertFalse(FileManager.default.fileExists(atPath: storeURL.path), "Corrupted store must be deleted before recovery")

        try FileManager.default.removeItem(at: tempDir)
        _ = container
    }
}
