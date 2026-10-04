import Foundation
import SwiftData

@Model
final class NowContext {
    var project: String
    var outcome: String
    var nextAction: String

    init(
        project: String = "NowNest",
        outcome: String = "Prove the save-and-resume loop",
        nextAction: String = "Save one real idea for later"
    ) {
        self.project = project
        self.outcome = outcome
        self.nextAction = nextAction
    }
}

@Model
final class SavedProject {
    var id: UUID
    var name: String
    var outcome: String
    var nextAction: String
    var isActive: Bool
    var createdAt: Date

    init(id: UUID = UUID(), name: String, outcome: String, nextAction: String, isActive: Bool = false, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.outcome = outcome
        self.nextAction = nextAction
        self.isActive = isActive
        self.createdAt = createdAt
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
    // Added after build 6; nil means the owner of a historical idea is uncertain.
    var projectID: UUID?
    var startingAction: String?
    var updatedAt: Date?
    var resumedAt: Date?
    var resolvedAt: Date?
    var resumeCount: Int?
    var parkCount: Int?
    // Optional fields preserve compatibility with stores created before reviews existed.
    var reviewStatus: String?
    var reviewInput: String?
    var reviewDraft: String?
    var reviewCategory: String?
    var reviewReason: String?
    var reviewUncertainty: String?
    var reviewMessage: String?
    var reviewRequestID: UUID?
    var reviewDecision: String?
    // Optional JSON fields allow existing SwiftData stores to migrate in place.
    var updatesJSON: String?
    var reviewHistoryJSON: String?

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
        self.projectID = nil
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

    static func sameProjectName(_ lhs: String, _ rhs: String) -> Bool {
        lhs.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            == rhs.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

@MainActor
enum NowNestStore {
    static func ensureProjects(in context: ModelContext, now: NowContext) throws {
        let projects = try context.fetch(FetchDescriptor<SavedProject>())
        if projects.isEmpty {
            let imported = SavedProject(name: now.project, outcome: now.outcome, nextAction: now.nextAction, isActive: true)
            context.insert(imported)
            // Build 6 recorded names, not identities. A matching name cannot prove ownership.
            // Every pre-ID idea remains visible for explicit assignment.
        } else {
            let active = projects.first(where: \.isActive) ?? projects.min(by: { $0.createdAt < $1.createdAt })!
            if !active.isActive { active.isActive = true }
            for project in projects where project.id != active.id && project.isActive { project.isActive = false }
        }
        try saveOrRollback(context)
    }

    static func assignImportedIdea(_ idea: ParkedIdea, to project: SavedProject, in context: ModelContext) throws -> Bool {
        guard idea.projectID == nil else { return false }
        guard idea.state == "PARKED" || idea.state == "RESUMED" else { return false }
        let projects = try context.fetch(FetchDescriptor<SavedProject>())
        guard projects.contains(where: { $0.id == project.id }) else { return false }
        if idea.state == "RESUMED" {
            let ideas = try context.fetch(FetchDescriptor<ParkedIdea>())
            guard !ideas.contains(where: { $0.state == "RESUMED" && $0.projectID == project.id }) else { return false }
        }
        idea.projectID = project.id
        try saveOrRollback(context)
        return true
    }

    static func addProject(name: String, outcome: String, nextAction: String, now: NowContext, in context: ModelContext) throws -> Bool {
        guard let values = NowNestRules.validNowValues(project: name, outcome: outcome, nextAction: nextAction) else { return false }
        let projects = try context.fetch(FetchDescriptor<SavedProject>())
        guard !projects.contains(where: { NowNestRules.sameProjectName($0.name, values.0) }) else { return false }
        for project in projects where project.isActive {
            project.name = now.project
            project.outcome = now.outcome
            project.nextAction = now.nextAction
            project.isActive = false
        }
        let added = SavedProject(name: values.0, outcome: values.1, nextAction: values.2, isActive: true)
        context.insert(added)
        now.project = values.0
        now.outcome = values.1
        now.nextAction = values.2
        try saveOrRollback(context)
        return true
    }

    static func switchProject(to target: SavedProject, now: NowContext, in context: ModelContext) throws {
        let projects = try context.fetch(FetchDescriptor<SavedProject>())
        guard projects.contains(where: { $0.id == target.id }) else { return }
        guard !target.isActive else { return }
        for project in projects where project.isActive {
            project.name = now.project
            project.outcome = now.outcome
            project.nextAction = now.nextAction
            project.isActive = false
        }
        target.isActive = true
        now.project = target.name
        now.outcome = target.outcome
        now.nextAction = target.nextAction
        try saveOrRollback(context)
    }

    static func ensureNow(in context: ModelContext, existing: NowContext?) throws {
        if let existing {
            var migrated = false
            if existing.outcome == "Prove the park-and-resume loop" {
                existing.outcome = "Prove the save-and-resume loop"
                migrated = true
            }
            if existing.nextAction == "Park one real idea" {
                existing.nextAction = "Save one real idea for later"
                migrated = true
            }
            if migrated { try context.save() }
            return
        }
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
        projectID: UUID? = nil,
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
        idea.projectID = projectID
        idea.reviewStatus = DeferredReviewStatus.queued.rawValue
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
        let active = try context.fetch(FetchDescriptor<ParkedIdea>()).first {
            $0.state == "RESUMED" && $0.projectID == idea.projectID
        }
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

        let projects = try context.fetch(FetchDescriptor<SavedProject>())
        guard !projects.contains(where: { $0.isActive == false && NowNestRules.sameProjectName($0.name, values.0) }) else {
            return false
        }
        now.project = values.0
        now.outcome = values.1
        now.nextAction = values.2
        if let active = projects.first(where: \.isActive) {
            active.name = values.0
            active.outcome = values.1
            active.nextAction = values.2
        }
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            throw error
        }
    }
}
