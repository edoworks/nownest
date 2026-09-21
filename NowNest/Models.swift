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

    init(text: String, id: UUID = UUID(), createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.state = "PARKED"
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

    static func park(_ text: String, in context: ModelContext) throws -> ParkedIdea? {
        guard let text = NowNestRules.normalized(text) else { return nil }

        let idea = ParkedIdea(text: text)
        context.insert(idea)
        do {
            try context.save()
            return idea
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
