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

    func testRecoverFromCorruptedStorePreservesRecoveryCopy() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nownest-recovery-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let storeURL = tempDir.appendingPathComponent("default.store")
        try Data("CORRUPTED-GARBAGE".utf8).write(to: storeURL)

        let schema = Schema([NowContext.self, ParkedIdea.self, DogfoodEvent.self])
        let (container, recoveryURL) = try NowNestApp.recoverFromCorruptedStore(at: storeURL, schema: schema)

        XCTAssertFalse(FileManager.default.fileExists(atPath: storeURL.path), "The live path must be available for a fresh store")
        XCTAssertNotNil(recoveryURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: recoveryURL!.appendingPathComponent("default.store").path))

        try FileManager.default.removeItem(at: tempDir)
        _ = container
    }

    @MainActor
    func testLifecyclePreservesContextAndRecordsContentFreeEvents() throws {
        let schema = Schema([NowContext.self, ParkedIdea.self, DogfoodEvent.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let idea = try XCTUnwrap(try NowNestStore.park(
            "Investigate Foundation Models",
            interruptedProject: "NowNest",
            interruptedOutcome: "Complete Customer Zero",
            interruptedNextAction: "Run the lifecycle tests",
            in: context
        ))
        XCTAssertEqual(idea.originProject, "NowNest")
        XCTAssertEqual(idea.originNextAction, "Run the lifecycle tests")

        XCTAssertTrue(try NowNestStore.resume(idea, startingAction: "Read Apple's Foundation Models docs", in: context))
        XCTAssertEqual(idea.state, "RESUMED")
        XCTAssertEqual(idea.startingAction, "Read Apple's Foundation Models docs")

        try NowNestStore.repark(idea, in: context)
        XCTAssertEqual(idea.state, "PARKED")
        try NowNestStore.complete(idea, in: context)
        XCTAssertEqual(idea.state, "DONE")
        XCTAssertFalse(try NowNestStore.resume(idea, startingAction: "Invalid restart", in: context))
        XCTAssertEqual(idea.state, "DONE")

        let events = try context.fetch(FetchDescriptor<DogfoodEvent>())
        XCTAssertEqual(events.map(\.kind), ["successfulPark", "resumed", "reparked", "completed"])
    }
}
