import XCTest
import SwiftData
@testable import NowNest

private actor ReviewProbe {
    var reviews = 0
    var critiques = 0
    var receivedDraft: String?
    var receivedInputs: [DeferredReviewInput] = []
    func reviewed(_ input: DeferredReviewInput? = nil) {
        reviews += 1
        if let input { receivedInputs.append(input) }
    }
    func critiqued(_ draft: String) { critiques += 1; receivedDraft = draft }
    func counts() -> [Int] { [reviews, critiques] }
}

// Frozen build-6 schema: it has review/update history but no saved project model
// or stable project ID on ideas.
private enum BeforeProjectSwitch {
@Model
final class ParkedIdea {
    var id: UUID
    var text: String
    var createdAt: Date
    var state: String
    var originProject: String?
    var originOutcome: String?
    var originNextAction: String?
    var startingAction: String?
    var updatedAt: Date?
    var resumedAt: Date?
    var resolvedAt: Date?
    var resumeCount: Int?
    var parkCount: Int?
    var reviewStatus: String?
    var reviewInput: String?
    var reviewDraft: String?
    var reviewCategory: String?
    var reviewReason: String?
    var reviewUncertainty: String?
    var reviewMessage: String?
    var reviewRequestID: UUID?
    var reviewDecision: String?
    var updatesJSON: String?
    var reviewHistoryJSON: String?

    init(text: String, originProject: String, state: String = "PARKED") {
        id = UUID()
        self.text = text
        createdAt = .now
        self.state = state
        self.originProject = originProject
        originOutcome = "Original outcome"
        originNextAction = "Original action"
        updatedAt = createdAt
        parkCount = 1
        resumeCount = 0
    }
}
}

@MainActor
extension DeferredReviewTests {
    func testSwitchDuringInflightReviewKeepsResultOnOriginalProject() async throws {
        let store = try container()
        let context = store.mainContext
        let now = NowContext(project: "First", outcome: "First outcome", nextAction: "First action")
        context.insert(now)
        try context.save()
        try NowNestStore.ensureProjects(in: context, now: now)
        let first = try XCTUnwrap(context.fetch(FetchDescriptor<SavedProject>()).first)
        let idea = try XCTUnwrap(NowNestStore.park("Review while switching", interruptedProject: now.project,
            interruptedOutcome: now.outcome, interruptedNextAction: now.nextAction, projectID: first.id, in: context))
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe, delay: .milliseconds(200)))
        coordinator.setActive(true, in: context)
        try await waitUntil { idea.deferredReviewStatus == .reviewing }
        XCTAssertTrue(try NowNestStore.addProject(name: "Second", outcome: "Second outcome", nextAction: "Second action", now: now, in: context))
        XCTAssertEqual(now.project, "Second")
        try await waitUntil { idea.deferredReviewStatus == .ready }
        XCTAssertEqual(idea.projectID, first.id)
        XCTAssertEqual(idea.originProject, "First")
        XCTAssertEqual(idea.reviewReason, summary.reason)
        let counts = await probe.counts()
        XCTAssertEqual(counts, [1, 1])
        try NowNestStore.switchProject(to: first, now: now, in: context)
        XCTAssertEqual(now.project, "First")
        XCTAssertEqual(idea.reviewReason, summary.reason)
    }

    func testBuild6SQLiteMigratesProjectsWithoutLosingReviewsOrInventingOwnership() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("project-build6-migration-\(UUID()).store")
        let ambiguousID: UUID
        let matchingID: UUID
        let updateJSON = #"[{"id":"16D5C535-DAE9-4878-A40B-A64DE65D0179","createdAt":"2026-10-03T00:00:00Z","text":"New context"}]"#
        let historyJSON = #"[{"id":"19FB4D41-8334-4C61-82D2-3A02CFABFB24","createdAt":"2026-10-03T00:00:00Z","category":"Needs clarification","reason":"Earlier result","uncertainty":"Unknown"}]"#
        do {
            let oldSchema = Schema([NowContext.self, BeforeProjectSwitch.ParkedIdea.self, DogfoodEvent.self])
            let old = try ModelContainer(for: oldSchema, configurations: ModelConfiguration(schema: oldSchema, url: url))
            old.mainContext.insert(NowContext(project: "Current", outcome: "Current outcome", nextAction: "Current action"))
            let ambiguous = BeforeProjectSwitch.ParkedIdea(text: "Keep original", originProject: "Earlier project", state: "RESUMED")
            ambiguous.startingAction = "Continue this"
            ambiguous.reviewStatus = "ready"
            ambiguous.reviewCategory = "Needs clarification"
            ambiguous.reviewReason = "Current result"
            ambiguous.updatesJSON = updateJSON
            ambiguous.reviewHistoryJSON = historyJSON
            ambiguousID = ambiguous.id
            let matching = BeforeProjectSwitch.ParkedIdea(text: "Still current", originProject: "Current")
            matching.reviewStatus = "queued"
            matching.reviewRequestID = UUID()
            matchingID = matching.id
            old.mainContext.insert(ambiguous)
            old.mainContext.insert(matching)
            try old.mainContext.save()
        }
        let importedProjectID: UUID
        do {
            let upgraded = try container(url: url)
            let context = upgraded.mainContext
            let now = try XCTUnwrap(context.fetch(FetchDescriptor<NowContext>()).first)
            try NowNestStore.ensureProjects(in: context, now: now)
            let project = try XCTUnwrap(context.fetch(FetchDescriptor<SavedProject>()).first)
            importedProjectID = project.id
            let ideas = try context.fetch(FetchDescriptor<ParkedIdea>())
            let ambiguous = try XCTUnwrap(ideas.first { $0.id == ambiguousID })
            let matching = try XCTUnwrap(ideas.first { $0.id == matchingID })
            XCTAssertNil(ambiguous.projectID)
            XCTAssertNil(matching.projectID)
            XCTAssertEqual(ambiguous.text, "Keep original")
            XCTAssertEqual(ambiguous.originProject, "Earlier project")
            XCTAssertEqual(ambiguous.startingAction, "Continue this")
            XCTAssertEqual(ambiguous.reviewReason, "Current result")
            XCTAssertEqual(ambiguous.updatesJSON, updateJSON)
            XCTAssertEqual(ambiguous.reviewHistoryJSON, historyJSON)
            XCTAssertEqual(matching.reviewStatus, "queued")
            XCTAssertNotNil(matching.reviewRequestID)
        }
        let reopened = try container(url: url)
        let context = reopened.mainContext
        let now = try XCTUnwrap(context.fetch(FetchDescriptor<NowContext>()).first)
        try NowNestStore.ensureProjects(in: context, now: now)
        XCTAssertEqual(try context.fetch(FetchDescriptor<SavedProject>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<SavedProject>()).first?.id, importedProjectID)
        let ambiguous = try XCTUnwrap(context.fetch(FetchDescriptor<ParkedIdea>()).first { $0.id == ambiguousID })
        XCTAssertNil(ambiguous.projectID)
        XCTAssertEqual(ambiguous.reviewHistoryJSON, historyJSON)
        let project = try XCTUnwrap(context.fetch(FetchDescriptor<SavedProject>()).first)
        XCTAssertTrue(try NowNestStore.assignImportedIdea(ambiguous, to: project, in: context))
        let assignedStore = try container(url: url)
        let assigned = try XCTUnwrap(assignedStore.mainContext.fetch(FetchDescriptor<ParkedIdea>()).first { $0.id == ambiguousID })
        XCTAssertEqual(assigned.projectID, importedProjectID)
        XCTAssertEqual(assigned.text, "Keep original")
        XCTAssertEqual(assigned.updatesJSON, updateJSON)
        XCTAssertEqual(assigned.reviewHistoryJSON, historyJSON)
    }
}

@MainActor
final class DeferredReviewTests: XCTestCase {
    private let summary = DeferredReviewSummary(category: "Needs clarification", reason: "Clarify the benefit.", uncertainty: "Effort is unknown.")

    private func container(url: URL? = nil) throws -> ModelContainer {
        let schema = Schema([NowContext.self, SavedProject.self, ParkedIdea.self, DogfoodEvent.self])
        let configuration = url.map { ModelConfiguration(schema: schema, url: $0) }
            ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    private func park(in context: ModelContext) throws -> ParkedIdea {
        try XCTUnwrap(try NowNestStore.park("Keep this exact thought", interruptedProject: "Project",
            interruptedOutcome: "Original outcome", interruptedNextAction: "Finish the current task", in: context))
    }

    private func waitUntil(_ condition: @escaping @MainActor () -> Bool, file: StaticString = #filePath, line: UInt = #line) async throws {
        for _ in 0..<300 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTFail("Condition did not become true", file: file, line: line)
    }

    private func client(_ probe: ReviewProbe, delay: Duration = .zero) -> DeferredReviewClient {
        let summary = summary
        return .init(review: { input in
            await probe.reviewed(input)
            try await Task.sleep(for: delay)
            return "Draft with an assumption to question."
        }, critique: { _, draft in
            await probe.critiqued(draft)
            return summary
        })
    }

    func testNewCaptureAutomaticallyReviewsThenCritiquesWithoutChangingOriginalOrNow() async throws {
        let store = try container()
        let context = store.mainContext
        let now = NowContext(project: "Original project", outcome: "Original outcome", nextAction: "Original action")
        context.insert(now)
        let idea = try park(in: context)
        let input = DeferredReviewInput(idea)
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe))
        XCTAssertEqual(idea.deferredReviewStatus, .queued)
        coordinator.setActive(true, in: context)
        try await waitUntil { idea.deferredReviewStatus == .ready }
        XCTAssertEqual(DeferredReviewInput(idea), input)
        XCTAssertEqual(idea.state, "PARKED")
        XCTAssertNil(idea.startingAction)
        XCTAssertEqual(now.nextAction, "Original action")
        XCTAssertEqual(now.project, "Original project")
        XCTAssertEqual(idea.reviewReason, summary.reason)
        XCTAssertEqual(idea.reviewUncertainty, summary.uncertainty)
        let counts = await probe.counts()
        let draft = await probe.receivedDraft
        XCTAssertEqual(counts, [1, 1])
        XCTAssertEqual(draft, idea.reviewDraft)
        XCTAssertEqual(try context.fetch(FetchDescriptor<DogfoodEvent>()).map(\.kind), ["successfulPark"])
    }

    func testDuplicateTriggersDoNotRepeatCompletedOrInFlightWork() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe, delay: .milliseconds(50)))
        coordinator.setActive(true, in: store.mainContext)
        for _ in 0..<20 { coordinator.kick(in: store.mainContext) }
        try await waitUntil { idea.deferredReviewStatus == .ready }
        coordinator.setActive(true, in: store.mainContext)
        coordinator.kick(in: store.mainContext)
        try await Task.sleep(for: .milliseconds(50))
        let counts = await probe.counts()
        XCTAssertEqual(counts, [1, 1])
    }

    func testUpdatePreservesOriginalShowsPreviousReviewAndUsesNewContext() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe))
        coordinator.setActive(true, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready }
        let originalReview = idea.reviewReason
        try coordinator.addUpdate("The budget is now $20.", to: idea, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready && idea.hasCurrentReview && idea.savedUpdates.count == 1 }
        XCTAssertEqual(idea.text, "Keep this exact thought")
        XCTAssertEqual(idea.originNextAction, "Finish the current task")
        XCTAssertEqual(idea.state, "PARKED")
        XCTAssertNil(idea.reviewDecision)
        XCTAssertEqual(idea.savedUpdates.map(\.text), ["The budget is now $20."])
        XCTAssertEqual(idea.savedReviewHistory.map(\.reason), [originalReview!])
        let inputs = await probe.receivedInputs
        XCTAssertEqual(inputs.count, 2)
        XCTAssertNil(inputs[0].updates)
        XCTAssertEqual(inputs[1].updates, ["The budget is now $20."])
        XCTAssertEqual(inputs[1].thought, inputs[0].thought)
        XCTAssertEqual(inputs[1].interruptedAction, inputs[0].interruptedAction)
    }

    func testMultipleUpdatesAccumulateWithoutLosingEarlierReviews() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe))
        coordinator.setActive(true, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready }
        try coordinator.addUpdate("First correction", to: idea, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready && idea.savedReviewHistory.count == 1 }
        try coordinator.addUpdate("Second correction", to: idea, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready && idea.savedReviewHistory.count == 2 }
        XCTAssertEqual(idea.savedUpdates.map(\.text), ["First correction", "Second correction"])
        let inputs = await probe.receivedInputs
        XCTAssertEqual(inputs.map(\.updates), [nil, ["First correction"], ["First correction", "Second correction"]])
        XCTAssertEqual(idea.savedReviewHistory.map(\.reason), [summary.reason, summary.reason])
        XCTAssertEqual(idea.state, "PARKED")
    }

    func testEmptyOversizedAndUnreadableUpdatesDoNotChangeIdea() throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let coordinator = DeferredReviewCoordinator(client: client(ReviewProbe()))
        XCTAssertThrowsError(try coordinator.addUpdate("  ", to: idea, in: store.mainContext))
        XCTAssertThrowsError(try coordinator.addUpdate(String(repeating: "a", count: 501), to: idea, in: store.mainContext))
        XCTAssertTrue(idea.savedUpdates.isEmpty)
        XCTAssertEqual(idea.deferredReviewStatus, .queued)
        idea.text = String(repeating: "x", count: 5500)
        try store.mainContext.save()
        XCTAssertThrowsError(try coordinator.addUpdate(String(repeating: "y", count: 500), to: idea, in: store.mainContext))
        XCTAssertNil(idea.updatesJSON)
        idea.updatesJSON = "invalid JSON"
        try store.mainContext.save()
        XCTAssertThrowsError(try coordinator.addUpdate("New context", to: idea, in: store.mainContext))
        XCTAssertEqual(idea.updatesJSON, "invalid JSON")
        XCTAssertEqual(idea.text, String(repeating: "x", count: 5500))
    }

    func testUpdateAndPreviousReviewSurviveRelaunchBeforeFreshReview() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("update-\(UUID()).store")
        let initialStore = try container(url: url)
        let idea = try park(in: initialStore.mainContext)
        let coordinator = DeferredReviewCoordinator(client: client(ReviewProbe()))
        coordinator.setActive(true, in: initialStore.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready }
        coordinator.setActive(false, in: initialStore.mainContext)
        try coordinator.addUpdate("A new constraint", to: idea, in: initialStore.mainContext)
        let reopened = try container(url: url)
        let saved = try XCTUnwrap(reopened.mainContext.fetch(FetchDescriptor<ParkedIdea>()).first)
        XCTAssertEqual(saved.savedUpdates.map(\.text), ["A new constraint"])
        XCTAssertEqual(saved.savedReviewHistory.count, 1)
        XCTAssertEqual(saved.deferredReviewStatus, .queued)
        XCTAssertEqual(saved.text, "Keep this exact thought")
        let probe = ReviewProbe()
        let relaunchedCoordinator = DeferredReviewCoordinator(client: client(probe))
        relaunchedCoordinator.setActive(true, in: reopened.mainContext)
        try await waitUntil { saved.deferredReviewStatus == .ready }
        let inputs = await probe.receivedInputs
        XCTAssertEqual(inputs.first?.updates, ["A new constraint"])
    }

    func testUpdateDuringReviewRejectsOldResultAndCanStillKeepOrDiscard() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe, delay: .milliseconds(80)))
        coordinator.setActive(true, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .reviewing }
        try coordinator.addUpdate("New information", to: idea, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready }
        let inputs = await probe.receivedInputs
        XCTAssertEqual(inputs.count, 2)
        XCTAssertEqual(inputs.last?.updates, ["New information"])
        XCTAssertEqual(idea.savedReviewHistory.count, 0)
        XCTAssertEqual(idea.state, "PARKED")
        try coordinator.keep(idea, in: store.mainContext)
        XCTAssertEqual(idea.reviewDecision, "kept")
        try coordinator.addUpdate("One more detail", to: idea, in: store.mainContext)
        XCTAssertNil(idea.reviewDecision)
        XCTAssertEqual(idea.state, "PARKED")
        try NowNestStore.abandon(idea, in: store.mainContext)
        XCTAssertEqual(idea.state, "ABANDONED")
        XCTAssertEqual(idea.text, "Keep this exact thought")
        XCTAssertEqual(idea.savedUpdates.map(\.text), ["New information", "One more detail"])
    }

    func testUnavailableFreshReviewKeepsSavedUpdateAndPreviousResult() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let summary = summary
        let client = DeferredReviewClient(review: { input in
            if input.updates != nil { throw DeferredReviewError.unavailable("Model unavailable") }
            return "The original first pass"
        }, critique: { _, _ in summary })
        let coordinator = DeferredReviewCoordinator(client: client)
        coordinator.setActive(true, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready }
        try coordinator.addUpdate("Changed circumstance", to: idea, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .unavailable }
        XCTAssertEqual(idea.savedUpdates.map(\.text), ["Changed circumstance"])
        XCTAssertEqual(idea.savedReviewHistory.first?.reason, summary.reason)
        XCTAssertEqual(idea.reviewMessage, "Model unavailable")
        XCTAssertNil(idea.reviewCategory)
        XCTAssertEqual(idea.state, "PARKED")
        XCTAssertEqual(idea.text, "Keep this exact thought")
    }

    func testUnavailableAndFailureRemainManualUntilExplicitRetry() async throws {
        for failure in [DeferredReviewError.unavailable("Unsupported device"), .unavailable("Model not ready"), .invalidOutput] {
            let store = try container()
            let idea = try park(in: store.mainContext)
            let probe = ReviewProbe()
            let summary = summary
            let client = DeferredReviewClient(review: { _ in await probe.reviewed(); throw failure }, critique: { _, _ in
                XCTFail("Must not critique a failed review")
                return summary
            })
            let coordinator = DeferredReviewCoordinator(client: client)
            coordinator.setActive(true, in: store.mainContext)
            try await waitUntil { idea.deferredReviewStatus == .unavailable || idea.deferredReviewStatus == .failed }
            coordinator.setActive(true, in: store.mainContext)
            try await Task.sleep(for: .milliseconds(30))
            var counts = await probe.counts()
            XCTAssertEqual(counts, [1, 0])
            XCTAssertEqual(idea.state, "PARKED")
            XCTAssertNil(idea.reviewCategory)
            XCTAssertNotNil(idea.reviewMessage)
            try coordinator.retry(idea, in: store.mainContext)
            try await waitUntil { idea.deferredReviewStatus == .unavailable || idea.deferredReviewStatus == .failed }
            counts = await probe.counts()
            XCTAssertEqual(counts, [2, 0])
        }
    }

    func testBackgroundCancellationPersistsPauseAndDoesNotAutomaticallyRetry() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe, delay: .seconds(10)))
        coordinator.setActive(true, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .reviewing }
        coordinator.setActive(false, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .interrupted }
        coordinator.setActive(true, in: store.mainContext)
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(idea.deferredReviewStatus, .interrupted)
        XCTAssertEqual(idea.text, "Keep this exact thought")
        XCTAssertEqual(idea.state, "PARKED")
        XCTAssertNil(idea.reviewCategory)
    }

    func testWorkerDoesNotStartWhileInactive() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe))
        coordinator.kick(in: store.mainContext)
        try await Task.sleep(for: .milliseconds(30))
        let counts = await probe.counts()
        XCTAssertEqual(counts, [0, 0])
        XCTAssertEqual(idea.deferredReviewStatus, .queued)
    }

    func testChangedInputAndResumeReparkRejectLateOutput() async throws {
        for mutateText in [true, false] {
            let store = try container()
            let idea = try park(in: store.mainContext)
            let probe = ReviewProbe()
            let coordinator = DeferredReviewCoordinator(client: client(probe, delay: .milliseconds(100)))
            coordinator.setActive(true, in: store.mainContext)
            try await waitUntil { idea.deferredReviewStatus == .reviewing }
            if mutateText {
                idea.text = "User edited text"
                try store.mainContext.save()
            } else {
                XCTAssertTrue(try NowNestStore.resume(idea, startingAction: "User action", in: store.mainContext))
                try NowNestStore.repark(idea, in: store.mainContext)
            }
            try await waitUntil { idea.deferredReviewStatus == .stale }
            XCTAssertNil(idea.reviewCategory)
            XCTAssertNil(idea.reviewDraft)
            XCTAssertEqual(idea.state, "PARKED")
            if mutateText { XCTAssertEqual(idea.text, "User edited text") }
        }
    }

    func testKeepAndDiscardDuringGenerationRejectLateOutputAndRetainContent() async throws {
        for discard in [true, false] {
            let store = try container()
            let idea = try park(in: store.mainContext)
            let input = DeferredReviewInput(idea)
            let probe = ReviewProbe()
            let coordinator = DeferredReviewCoordinator(client: client(probe, delay: .milliseconds(80)))
            coordinator.setActive(true, in: store.mainContext)
            try await waitUntil { idea.deferredReviewStatus == .reviewing }
            if discard { try NowNestStore.abandon(idea, in: store.mainContext) }
            else { try coordinator.keep(idea, in: store.mainContext) }
            try await Task.sleep(for: .milliseconds(150))
            XCTAssertNil(idea.reviewCategory)
            XCTAssertEqual(DeferredReviewInput(idea), input)
            XCTAssertEqual(idea.state, discard ? "ABANDONED" : "PARKED")
            XCTAssertEqual(try store.mainContext.fetchCount(FetchDescriptor<ParkedIdea>()), 1)
            let counts = await probe.counts()
            XCTAssertEqual(counts, [1, 0])
        }
    }

    func testTimeoutBecomesRetryableFailure() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let coordinator = DeferredReviewCoordinator(client: client(ReviewProbe(), delay: .seconds(10)), timeout: .milliseconds(20))
        coordinator.setActive(true, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .failed }
        XCTAssertTrue(idea.reviewMessage?.contains("too long") == true)
        XCTAssertNil(idea.reviewCategory)
    }

    func testOversizedInputAndMalformedSummaryAreNotPresentedAsAdvice() async throws {
        for oversized in [true, false] {
            let store = try container()
            let idea = try park(in: store.mainContext)
            if oversized { idea.text = String(repeating: "a", count: 6001); try store.mainContext.save() }
            let probe = ReviewProbe()
            let client = DeferredReviewClient(review: { _ in await probe.reviewed(); return "Draft" }, critique: { _, _ in
                DeferredReviewSummary(category: "Unsupported category", reason: "Reason", uncertainty: "")
            })
            let coordinator = DeferredReviewCoordinator(client: client)
            coordinator.setActive(true, in: store.mainContext)
            try await waitUntil { idea.deferredReviewStatus == .failed }
            XCTAssertNil(idea.reviewCategory)
            XCTAssertEqual(idea.state, "PARKED")
            if oversized {
                let counts = await probe.counts()
                XCTAssertEqual(counts, [0, 0])
                XCTAssertEqual(idea.text.count, 6001)
            }
        }
    }

    func testRelaunchRestoresInterruptedCritiqueAndRetryReusesPersistedDraft() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("review-\(UUID()).store")
        try seedInterruptedStore(at: url)
        let reopened = try container(url: url)
        let idea = try XCTUnwrap(reopened.mainContext.fetch(FetchDescriptor<ParkedIdea>()).first)
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe))
        coordinator.setActive(true, in: reopened.mainContext)
        XCTAssertEqual(idea.deferredReviewStatus, .interrupted)
        XCTAssertEqual(idea.reviewDraft, "Persisted first-pass review")
        XCTAssertEqual(idea.originNextAction, "Finish the current task")
        try coordinator.retry(idea, in: reopened.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready }
        let counts = await probe.counts()
        XCTAssertEqual(counts, [0, 1])
        let verificationContext = ModelContext(reopened)
        let saved = try XCTUnwrap(verificationContext.fetch(FetchDescriptor<ParkedIdea>()).first)
        XCTAssertEqual(saved.reviewReason, summary.reason)
        XCTAssertEqual(saved.state, "PARKED")
        XCTAssertEqual(saved.text, "Keep this exact thought")
    }

    private func seedInterruptedStore(at url: URL) throws {
        let store = try container(url: url)
        let idea = try park(in: store.mainContext)
        idea.reviewStatus = DeferredReviewStatus.critiquing.rawValue
        idea.reviewDraft = "Persisted first-pass review"
        idea.reviewInput = DeferredReviewInput(idea).snapshot
        idea.reviewRequestID = UUID()
        try store.mainContext.save()
    }

    func testOldIdeasAreNotAutomaticallyBackfilled() async throws {
        let store = try container()
        let legacy = ParkedIdea(text: "Existing idea")
        store.mainContext.insert(legacy)
        try store.mainContext.save()
        let probe = ReviewProbe()
        let coordinator = DeferredReviewCoordinator(client: client(probe))
        coordinator.setActive(true, in: store.mainContext)
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertNil(legacy.reviewStatus)
        let counts = await probe.counts()
        XCTAssertEqual(counts, [0, 0])
        try coordinator.retry(legacy, in: store.mainContext)
        try await waitUntil { legacy.deferredReviewStatus == .ready }
    }
}

// Frozen pre-feature model: verifies a real SQLite lightweight migration.
private enum BeforeDeferredReview {
@Model
final class ParkedIdea {
    var id: UUID
    var text: String
    var createdAt: Date
    var state: String
    var originProject: String?
    var originOutcome: String?
    var originNextAction: String?
    var startingAction: String?
    var updatedAt: Date?
    var resumedAt: Date?
    var resolvedAt: Date?
    var resumeCount: Int?
    var parkCount: Int?

    init(
        text: String,
        id: UUID = UUID(),
        createdAt: Date = .now,
        originProject: String? = nil,
        originOutcome: String? = nil,
        originNextAction: String? = nil
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.state = "PARKED"
        self.originProject = originProject
        self.originOutcome = originOutcome
        self.originNextAction = originNextAction
        self.startingAction = nil
        self.updatedAt = createdAt
        self.resumedAt = nil
        self.resolvedAt = nil
        self.resumeCount = 0
        self.parkCount = 1
    }
}

}

// Frozen build 5 model: an existing reviewed idea must remain readable after
// the two optional update/history fields are added.
private enum BeforeIdeaUpdates {
@Model
final class ParkedIdea {
    var id: UUID
    var text: String
    var createdAt: Date
    var state: String
    var originProject: String?
    var originOutcome: String?
    var originNextAction: String?
    var startingAction: String?
    var updatedAt: Date?
    var resumedAt: Date?
    var resolvedAt: Date?
    var resumeCount: Int?
    var parkCount: Int?
    var reviewStatus: String?
    var reviewInput: String?
    var reviewDraft: String?
    var reviewCategory: String?
    var reviewReason: String?
    var reviewUncertainty: String?
    var reviewMessage: String?
    var reviewRequestID: UUID?
    var reviewDecision: String?

    init() {
        id = UUID()
        text = "Build 5 thought"
        createdAt = .now
        state = "PARKED"
        originProject = "Old project"
        originOutcome = "Old outcome"
        originNextAction = "Old action"
        parkCount = 1
        reviewStatus = "ready"
        reviewInput = #"{"interruptedAction":"Old action","outcome":"Old outcome","parkCount":1,"project":"Old project","thought":"Build 5 thought"}"#
        reviewDraft = "Old first pass"
        reviewCategory = "Needs clarification"
        reviewReason = "Old result"
        reviewUncertainty = "Old uncertainty"
    }
}
}

@MainActor
extension DeferredReviewTests {
    func testBuild5ReviewedIdeaMigratesAndStillShowsItsReview() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("update-migration-\(UUID()).store")
        let oldSchema = Schema([NowContext.self, BeforeIdeaUpdates.ParkedIdea.self, DogfoodEvent.self])
        let old = try ModelContainer(for: oldSchema, configurations: ModelConfiguration(schema: oldSchema, url: url))
        old.mainContext.insert(BeforeIdeaUpdates.ParkedIdea())
        try old.mainContext.save()
        let migrated = try container(url: url)
        let idea = try XCTUnwrap(migrated.mainContext.fetch(FetchDescriptor<ParkedIdea>()).first)
        XCTAssertEqual(idea.text, "Build 5 thought")
        XCTAssertEqual(idea.originNextAction, "Old action")
        XCTAssertEqual(idea.reviewReason, "Old result")
        XCTAssertTrue(idea.hasCurrentReview)
        XCTAssertNil(idea.updatesJSON)
        XCTAssertNil(idea.reviewHistoryJSON)
    }

    func testExistingStoreMigratesWithoutLosingOriginalContextOrBackfilling() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("review-migration-\(UUID()).store")
        try seedLegacyStore(at: url)
        let store = try container(url: url)
        let idea = try XCTUnwrap(store.mainContext.fetch(FetchDescriptor<ParkedIdea>()).first)
        XCTAssertEqual(idea.text, "Pre-feature original")
        XCTAssertEqual(idea.originProject, "Existing project")
        XCTAssertEqual(idea.originOutcome, "Existing outcome")
        XCTAssertEqual(idea.originNextAction, "Existing action")
        XCTAssertEqual(idea.state, "PARKED")
        XCTAssertNil(idea.reviewStatus)
        XCTAssertNil(idea.reviewDraft)
        XCTAssertNil(idea.reviewDecision)
    }

    private func seedLegacyStore(at url: URL) throws {
        let schema = Schema([NowContext.self, BeforeDeferredReview.ParkedIdea.self, DogfoodEvent.self])
        let store = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
        store.mainContext.insert(BeforeDeferredReview.ParkedIdea(text: "Pre-feature original", originProject: "Existing project",
            originOutcome: "Existing outcome", originNextAction: "Existing action"))
        try store.mainContext.save()
    }
}

@MainActor
extension DeferredReviewTests {
    func testCritiqueFailureRetainsDraftAndExplicitRetryDoesNotRepeatReview() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let probe = ReviewProbe()
        let summary = summary
        let client = DeferredReviewClient(review: { _ in
            await probe.reviewed()
            return "A saved first pass."
        }, critique: { _, draft in
            await probe.critiqued(draft)
            if await probe.counts()[1] == 1 { throw DeferredReviewError.invalidOutput }
            return summary
        })
        let coordinator = DeferredReviewCoordinator(client: client)
        coordinator.setActive(true, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .failed }
        XCTAssertEqual(idea.reviewDraft, "A saved first pass.")
        XCTAssertNil(idea.reviewCategory)
        try coordinator.retry(idea, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .ready }
        let counts = await probe.counts()
        XCTAssertEqual(counts, [1, 2])
    }

    func testCancelledModelReturningLateCannotPublishResult() async throws {
        let store = try container()
        let idea = try park(in: store.mainContext)
        let summary = summary
        let client = DeferredReviewClient(review: { _ in
            // Simulate a model returning a value even after cancellation was requested.
            try? await Task.sleep(for: .seconds(10))
            return "A late draft"
        }, critique: { _, _ in summary })
        let coordinator = DeferredReviewCoordinator(client: client)
        coordinator.setActive(true, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .reviewing }
        coordinator.setActive(false, in: store.mainContext)
        try await waitUntil { idea.deferredReviewStatus == .interrupted }
        XCTAssertNil(idea.reviewDraft)
        XCTAssertNil(idea.reviewCategory)
        XCTAssertEqual(idea.state, "PARKED")
    }
}
