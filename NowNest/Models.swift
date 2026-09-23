import Foundation
import SwiftData

@Model
final class NowContext {
    var project: String
    var outcome: String
    var nextAction: String

    init(
        project: String = "NowNest",
        outcome: String = "Prove the park-and-resume loop",
        nextAction: String = "Park one real idea"
    ) {
        self.project = project
        self.outcome = outcome
        self.nextAction = nextAction
    }
}

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

@Model
final class DogfoodEvent {
    var id: UUID
    var kind: String
    var createdAt: Date

    init(kind: String, createdAt: Date = .now) {
        self.id = UUID()
        self.kind = kind
        self.createdAt = createdAt
    }
}

enum NowNestRules {
    static func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func validNowValues(project: String, outcome: String, nextAction: String) -> (String, String, String)? {
        guard
            let project = normalized(project),
            let outcome = normalized(outcome),
            let nextAction = normalized(nextAction)
        else {
            return nil
        }
        return (project, outcome, nextAction)
    }
}

@MainActor
enum NowNestStore {
    static func ensureNow(in context: ModelContext, existing: NowContext?) throws {
        guard existing == nil else { return }
        context.insert(NowContext())
        try context.save()
    }

    static func record(_ kind: String, in context: ModelContext) {
        context.insert(DogfoodEvent(kind: kind))
    }

    static func park(
        _ text: String,
        interruptedProject: String,
        interruptedOutcome: String,
        interruptedNextAction: String,
        in context: ModelContext
    ) throws -> ParkedIdea? {
        guard let text = NowNestRules.normalized(text) else { return nil }

        let idea = ParkedIdea(
            text: text,
            originProject: interruptedProject,
            originOutcome: interruptedOutcome,
            originNextAction: interruptedNextAction
        )
        context.insert(idea)
        record("successfulPark", in: context)
        do {
            try context.save()
            return idea
        } catch {
            context.rollback()
            throw error
        }
    }

    static func resume(_ idea: ParkedIdea, startingAction: String, in context: ModelContext) throws -> Bool {
        guard let startingAction = NowNestRules.normalized(startingAction) else { return false }
        guard idea.state == "PARKED" else { return false }
        let active = try context.fetch(FetchDescriptor<ParkedIdea>()).first { $0.state == "RESUMED" }
        guard active == nil else { return false }

        idea.state = "RESUMED"
        idea.startingAction = startingAction
        idea.resumedAt = .now
        idea.updatedAt = .now
        idea.resumeCount = (idea.resumeCount ?? 0) + 1
        record("resumed", in: context)
        try saveOrRollback(context)
        return true
    }

    static func repark(_ idea: ParkedIdea, in context: ModelContext) throws {
        guard idea.state == "RESUMED" else { return }
        idea.state = "PARKED"
        idea.updatedAt = .now
        idea.parkCount = (idea.parkCount ?? 1) + 1
        record("reparked", in: context)
        try saveOrRollback(context)
    }

    static func complete(_ idea: ParkedIdea, in context: ModelContext) throws {
        guard idea.state == "PARKED" || idea.state == "RESUMED" else { return }
        idea.state = "DONE"
        idea.updatedAt = .now
        idea.resolvedAt = .now
        record("completed", in: context)
        try saveOrRollback(context)
    }

    static func abandon(_ idea: ParkedIdea, in context: ModelContext) throws {
        guard idea.state == "PARKED" || idea.state == "RESUMED" else { return }
        idea.state = "ABANDONED"
        idea.updatedAt = .now
        idea.resolvedAt = .now
        record("abandoned", in: context)
        try saveOrRollback(context)
    }

    private static func saveOrRollback(_ context: ModelContext) throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    static func update(
        _ now: NowContext,
        project: String,
        outcome: String,
        nextAction: String,
        in context: ModelContext
    ) throws -> Bool {
        guard let values = NowNestRules.validNowValues(
            project: project,
            outcome: outcome,
            nextAction: nextAction
        ) else {
            return false
        }

        now.project = values.0
        now.outcome = values.1
        now.nextAction = values.2
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            throw error
        }
    }
}
