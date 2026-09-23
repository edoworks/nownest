import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.visualVariantConfiguration) private var variantConfig
    @Environment(\.recoveryNotice) private var recoveryNotice
    @Query private var nowContexts: [NowContext]
    @Query(sort: \ParkedIdea.createdAt, order: .reverse) private var ideas: [ParkedIdea]

    @AppStorage("quietModeEnabled") private var quietModeStored = false
    @State private var presentedSheet: Sheet?
    @State private var confirmation: String?
    @State private var errorMessage: String?
    @State private var showTuckedPose = false
    @State private var recoveryAlertPresented = false

    private enum Sheet: Identifiable {
        case capture
        case edit
        case review

        var id: Self { self }
    }

    private var now: NowContext? { nowContexts.first }
    private var activeIdea: ParkedIdea? { ideas.first { $0.state == "RESUMED" } }
    private var parkedCount: Int { ideas.count { $0.state == "PARKED" } }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.nestCanvas, Color.nestSurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if variantConfig.variant != .control {
                    NestMotif()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(Color.nestHoneyLight.opacity(0.15))
                        .position(x: UIScreen.main.bounds.width * 0.85, y: UIScreen.main.bounds.height * 0.15)
                        .accessibilityHidden(true)
                }

                if let now {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            if let activeIdea {
                                activeCard(activeIdea)
                            } else {
                                nowCard(now)
                            }

                            Button {
                                NowNestStore.record("captureAttempt", in: modelContext)
                                presentedSheet = .capture
                            } label: {
                                Label("Park an idea", systemImage: "arrow.down.to.line.compact")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.nestHoney)
                            .controlSize(.large)
                            .accessibilityIdentifier("parkIdeaButton")

                            Button {
                                NowNestStore.record("resurfaced", in: modelContext)
                                try? modelContext.save()
                                presentedSheet = .review
                            } label: {
                                Label("Parked ideas (\(parkedCount))", systemImage: "archivebox")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("reviewParkedButton")

                            if variantConfig.showsReassurance {
                                Text("Capture it safely, then return here. Nothing changes NOW unless you edit it.")
                                    .font(NestTypography.reassurance)
                                    .foregroundStyle(Color.nestInkMuted)
                                    .frame(maxWidth: 420, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: 680, alignment: .leading)
                        .padding(24)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ProgressView("Preparing NOW")
                }
            }
            .navigationTitle("NowNest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NestWordmark()
                        .accessibilityIdentifier("nestWordmark")
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Edit NOW", systemImage: "pencil") {
                            presentedSheet = .edit
                        }
                        .disabled(now == nil)

                        Button("Review parked ideas", systemImage: "archivebox") {
                            NowNestStore.record("resurfaced", in: modelContext)
                            try? modelContext.save()
                            presentedSheet = .review
                        }

                        if variantConfig.variant != .control {
                            Divider()
                            Toggle("Quiet Mode", isOn: $quietModeStored)
                                .accessibilityIdentifier("quietModeToggle")
                        }
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let confirmation {
                    HStack(spacing: 10) {
                        if showTuckedPose && !reduceMotion {
                            if variantConfig.showsSophie {
                                SophieMark(pose: .tucked, size: 24)
                                    .accessibilityHidden(true)
                                    .transition(.scale.combined(with: .opacity))
                            } else if variantConfig.variant != .control {
                                TuckedNoteIllustration(size: 32)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        Text(confirmation)
                            .font(NestTypography.confirmation)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        variantConfig.variant == .control ? Color.nestInk :
                            (showTuckedPose && !reduceMotion ? Color.nestSage : Color.nestInk),
                        in: Capsule()
                    )
                    .padding(.bottom, 8)
                    .accessibilityIdentifier("parkConfirmation")
                }
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .capture:
                    if let now {
                        let context = interruptionContext(now)
                        CaptureView(
                            nextAction: context.nextAction,
                            onCancel: recordAbandonedCapture
                        ) { text in
                            park(text, interruptedBy: context)
                        }
                    }
                case .edit:
                    if let now {
                        EditNowView(now: now) { project, outcome, nextAction in
                            update(now, project: project, outcome: outcome, nextAction: nextAction)
                        }
                    }
                case .review:
                    ReviewView { presentedSheet = nil }
                }
            }
            .alert("Couldn’t save", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Couldn't save.")
            }
            .alert("Local data recovery", isPresented: $recoveryAlertPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(recoveryNotice ?? "A recovery copy was preserved.")
            }
            .task {
                do {
                    try NowNestStore.ensureNow(in: modelContext, existing: now)
                } catch {
                    errorMessage = "Couldn't create NOW."
                }
                recoveryAlertPresented = recoveryNotice != nil
            }
        }
    }

    private func nowCard(_ now: NowContext) -> some View {
        NestCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 12) {
                    Text("NOW")
                        .font(NestTypography.nowHeading)
                        .tracking(2.4)
                        .foregroundStyle(Color.nestInkMuted)

                    if variantConfig.showsSophie {
                        SophieMark(pose: .resting, size: 22)
                            .accessibilityHidden(true)
                    }
                }

                nowField("PROJECT", value: now.project)
                Divider()
                nowField("OUTCOME", value: now.outcome)
                Divider()
                nowField("NEXT ACTION", value: now.nextAction, emphasized: true)

                if variantConfig.variant != .control {
                    NestMotif()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(Color.nestHoney.opacity(0.4))
                        .accessibilityHidden(true)
                }
            }
        }
        .nestShadow()
        .accessibilityIdentifier("nowCard")
    }

    private func activeCard(_ idea: ParkedIdea) -> some View {
        NestCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("NOW")
                    .font(NestTypography.nowHeading)
                    .tracking(2.4)
                    .foregroundStyle(Color.nestInkMuted)
                nowField("INTENTION", value: idea.text)
                Divider()
                nowField("NEXT ACTION", value: idea.startingAction ?? idea.text, emphasized: true)

                if let originProject = idea.originProject, let originNextAction = idea.originNextAction {
                    Text("Parked while working on \(originProject): \(originNextAction)")
                        .font(.footnote)
                        .foregroundStyle(Color.nestInkMuted)
                        .accessibilityIdentifier("resumeContext")
                }

                HStack {
                    Button("Done", systemImage: "checkmark") { resolveActive(idea, action: .complete) }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("completeActiveButton")
                    Button("Re-park", systemImage: "arrow.uturn.backward") { resolveActive(idea, action: .repark) }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("reparkActiveButton")
                    Menu {
                        Button("Abandon", systemImage: "trash", role: .destructive) {
                            resolveActive(idea, action: .abandon)
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .nestShadow()
    }

    private func nowField(_ label: String, value: String, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(NestTypography.fieldLabel)
                .tracking(1.2)
                .foregroundStyle(Color.nestInkMuted)
            Text(value)
                .font(emphasized ? (variantConfig.variant == .control ? NestTypography.nextActionValueControl : NestTypography.nextActionValueExpressive) : NestTypography.fieldValue)
                .foregroundStyle(Color.nestInk)
                .accessibilityIdentifier(label.lowercased().replacingOccurrences(of: " ", with: ""))
        }
    }

    private typealias InterruptionContext = (project: String, outcome: String, nextAction: String)

    private func interruptionContext(_ now: NowContext) -> InterruptionContext {
        guard let activeIdea else { return (now.project, now.outcome, now.nextAction) }
        return (
            activeIdea.originProject ?? activeIdea.text,
            activeIdea.text,
            activeIdea.startingAction ?? activeIdea.text
        )
    }

    private func park(_ text: String, interruptedBy context: InterruptionContext) -> Bool {
        do {
            guard try NowNestStore.park(
                text,
                interruptedProject: context.project,
                interruptedOutcome: context.outcome,
                interruptedNextAction: context.nextAction,
                in: modelContext
            ) != nil else { return false }
            presentedSheet = nil
            showTuckedPose = variantConfig.variant != .control
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if reduceMotion {
                confirmation = variantConfig.confirmationCopy(for: context.nextAction)
            } else {
                withAnimation(.easeOut(duration: 0.45)) {
                    confirmation = variantConfig.confirmationCopy(for: context.nextAction)
                }
            }
            Task {
                try? await Task.sleep(for: .seconds(3))
                if reduceMotion {
                    confirmation = nil
                } else {
                    withAnimation(.easeOut) {
                        confirmation = nil
                        showTuckedPose = false
                    }
                }
            }
            return true
        } catch {
            errorMessage = "Couldn't park."
            return false
        }
    }

    private enum ActiveResolution { case complete, repark, abandon }

    private func resolveActive(_ idea: ParkedIdea, action: ActiveResolution) {
        do {
            switch action {
            case .complete: try NowNestStore.complete(idea, in: modelContext)
            case .repark: try NowNestStore.repark(idea, in: modelContext)
            case .abandon: try NowNestStore.abandon(idea, in: modelContext)
            }
        } catch {
            errorMessage = "Couldn't update this idea."
        }
    }

    private func recordAbandonedCapture() {
        NowNestStore.record("abandonedCapture", in: modelContext)
        try? modelContext.save()
    }

    private func update(
        _ now: NowContext,
        project: String,
        outcome: String,
        nextAction: String
    ) -> Bool {
        do {
            let saved = try NowNestStore.update(
                now,
                project: project,
                outcome: outcome,
                nextAction: nextAction,
                in: modelContext
            )
            if saved { presentedSheet = nil }
            return saved
        } catch {
            errorMessage = "Couldn't save NOW."
            return false
        }
    }
}

private struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.visualVariantConfiguration) private var variantConfig
    @FocusState private var isFocused: Bool
    @State private var text = ""
    @State private var didPark = false

    let nextAction: String
    let onCancel: () -> Void
    let onPark: (String) -> Bool

    private var isValid: Bool { NowNestRules.normalized(text) != nil }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if variantConfig.showsCaptureTitle {
                    Text("Make it safe to forget.")
                        .font(NestTypography.captureTitle)
                        .foregroundStyle(Color.nestInk)
                }

                NestPaperNote {
                    TextField("What showed up?", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .accessibilityIdentifier("ideaField")
                }

                HStack(alignment: .top, spacing: 12) {
                    Text("\(variantConfig.returnTargetPrefix)\(nextAction)")
                        .font(NestTypography.reassurance)
                        .foregroundStyle(Color.nestInkMuted)

                    if variantConfig.showsSophie {
                        SophieMark(pose: .guarding, size: 20)
                            .accessibilityHidden(true)
                    }
                }

                Spacer()
            }
            .padding(24)
            .background(variantConfig.variant == .control ? Color.clear : Color.nestCanvas.opacity(0.5))
            .navigationTitle("Park an idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Park") {
                        if onPark(text) { didPark = true }
                    }
                        .disabled(!isValid)
                        .accessibilityIdentifier("confirmParkButton")
                }
            }
            .task { isFocused = true }
        }
        .presentationDetents([.medium, .large])
        .onDisappear {
            if !didPark { onCancel() }
        }
    }
}

private struct EditNowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var project: String
    @State private var outcome: String
    @State private var nextAction: String

    let onSave: (String, String, String) -> Bool

    init(now: NowContext, onSave: @escaping (String, String, String) -> Bool) {
        _project = State(initialValue: now.project)
        _outcome = State(initialValue: now.outcome)
        _nextAction = State(initialValue: now.nextAction)
        self.onSave = onSave
    }

    private var isValid: Bool {
        [project, outcome, nextAction].allSatisfy { NowNestRules.normalized($0) != nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("NOW") {
                    TextField("Project", text: $project)
                    TextField("Outcome", text: $outcome, axis: .vertical)
                    TextField("Next Action", text: $nextAction, axis: .vertical)
                }
            }
            .navigationTitle("Edit NOW")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { _ = onSave(project, outcome, nextAction) }
                        .disabled(!isValid)
                }
            }
        }
    }
}

private struct ReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.visualVariantConfiguration) private var variantConfig
    @Query(sort: \ParkedIdea.createdAt, order: .reverse) private var ideas: [ParkedIdea]
    @State private var updateFailed = false

    let onResumed: () -> Void

    private var parkedIdeas: [ParkedIdea] { ideas.filter { $0.state == "PARKED" } }

    var body: some View {
        NavigationStack {
            Group {
                if parkedIdeas.isEmpty {
                    emptyState
                } else {
                    ideaList
                }
            }
            .navigationTitle("Parked ideas")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Couldn’t update", isPresented: $updateFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The parked idea is still present.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            if variantConfig.variant != .control {
                NestIllustration(size: 120)
            } else if variantConfig.showsSophie {
                SophieMark(pose: .resting, size: 40)
                    .accessibilityHidden(true)
            }
            ContentUnavailableView(
                "Nothing parked",
                systemImage: variantConfig.variant == .control ? "archivebox" : "",
                description: Text(variantConfig.isQuiet ? "Park an idea to fill the nest." : "Ideas appear here only after you park them.")
            )
        }
    }

    private var ideaList: some View {
        List(parkedIdeas) { idea in
            NavigationLink {
                ParkedIdeaDetailView(idea: idea) {
                    onResumed()
                }
            } label: {
                VStack(alignment: .leading, spacing: 7) {
                    Text(idea.text)
                        .font(.body)
                        .foregroundStyle(Color.nestInk)
                    if let originProject = idea.originProject {
                        Text("Parked from \(originProject)")
                            .font(.caption)
                            .foregroundStyle(Color.nestInkMuted)
                    }
                    HStack {
                        Text("READY")
                            .font(.caption2.weight(.black))
                            .tracking(1)
                            .foregroundStyle(Color.nestSage)
                        Spacer()
                        Text(idea.createdAt, format: .dateTime.month().day().hour().minute())
                            .foregroundStyle(Color.nestInkMuted)
                    }
                }
            }
            .accessibilityIdentifier("parkedIdeaRow")
            .listRowBackground(
                variantConfig.variant == .control ? Color(.secondarySystemBackground) : Color.nestSurfaceRaised.opacity(0.5)
            )
            .swipeActions {
                Button("Done") {
                    do { try NowNestStore.complete(idea, in: modelContext) }
                    catch { updateFailed = true }
                }
                .tint(Color.nestSage)
                Button("Abandon", role: .destructive) {
                    do { try NowNestStore.abandon(idea, in: modelContext) }
                    catch { updateFailed = true }
                }
            }
        }
        .scrollContentBackground(variantConfig.variant == .control ? .automatic : .hidden)
        .background(variantConfig.variant == .control ? Color.clear : Color.nestCanvas.opacity(0.3))
    }
}

private struct ParkedIdeaDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var startingAction: String
    @State private var saveFailed = false

    let idea: ParkedIdea
    let onResumed: () -> Void

    init(idea: ParkedIdea, onResumed: @escaping () -> Void) {
        self.idea = idea
        self.onResumed = onResumed
        _startingAction = State(initialValue: idea.startingAction ?? idea.text)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Original thought") {
                    Text(idea.text)
                        .accessibilityIdentifier("originalThought")
                }

                if idea.originProject != nil || idea.originOutcome != nil || idea.originNextAction != nil {
                    Section("Why it was parked") {
                        if let value = idea.originProject { LabeledContent("Project", value: value) }
                        if let value = idea.originOutcome { LabeledContent("Outcome", value: value) }
                        if let value = idea.originNextAction { LabeledContent("You were doing", value: value) }
                    }
                }

                Section("Starting point") {
                    TextField("First concrete action", text: $startingAction, axis: .vertical)
                        .accessibilityIdentifier("startingActionField")
                    Text("This is your choice, not a generated fact.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Resume", systemImage: "play.fill") { resume() }
                        .disabled(NowNestRules.normalized(startingAction) == nil)
                        .accessibilityIdentifier("resumeIdeaButton")
                    Button("Done", systemImage: "checkmark") { complete() }
                    Button("Abandon", systemImage: "trash", role: .destructive) { abandon() }
                }
            }
            .navigationTitle("Ready to resume")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Couldn’t update", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func resume() {
        do {
            if try NowNestStore.resume(idea, startingAction: startingAction, in: modelContext) {
                dismiss()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    onResumed()
                }
            }
        } catch {
            saveFailed = true
        }
    }

    private func complete() {
        do {
            try NowNestStore.complete(idea, in: modelContext)
            dismiss()
        } catch {
            saveFailed = true
        }
    }

    private func abandon() {
        do {
            try NowNestStore.abandon(idea, in: modelContext)
            dismiss()
        } catch {
            saveFailed = true
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [NowContext.self, ParkedIdea.self, DogfoodEvent.self], inMemory: true)
}
