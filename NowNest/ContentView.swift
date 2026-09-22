import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.visualVariantConfiguration) private var variantConfig
    @Query private var nowContexts: [NowContext]

    @AppStorage("quietModeEnabled") private var quietModeStored = false
    @State private var presentedSheet: Sheet?
    @State private var confirmation: String?
    @State private var errorMessage: String?
    @State private var showTuckedPose = false

    private enum Sheet: Identifiable {
        case capture
        case edit
        case review

        var id: Self { self }
    }

    private var now: NowContext? { nowContexts.first }

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
                            nowCard(now)

                            Button {
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
                        if showTuckedPose && variantConfig.showsSophie && !reduceMotion {
                            SophieMark(pose: .tucked, size: 24)
                                .accessibilityHidden(true)
                                .transition(.scale.combined(with: .opacity))
                        }
                        Text(confirmation)
                            .font(.subheadline.weight(.semibold))
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
                        CaptureView(nextAction: now.nextAction) { text in
                            park(text, returningTo: now.nextAction)
                        }
                    }
                case .edit:
                    if let now {
                        EditNowView(now: now) { project, outcome, nextAction in
                            update(now, project: project, outcome: outcome, nextAction: nextAction)
                        }
                    }
                case .review:
                    ReviewView()
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
            .task {
                do {
                    try NowNestStore.ensureNow(in: modelContext, existing: now)
                } catch {
                    errorMessage = "Couldn't create NOW."
                }
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

    private func park(_ text: String, returningTo nextAction: String) -> Bool {
        do {
            guard try NowNestStore.park(text, in: modelContext) != nil else { return false }
            presentedSheet = nil
            showTuckedPose = variantConfig.variant != .control
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            if reduceMotion {
                confirmation = variantConfig.confirmationCopy(for: nextAction)
            } else {
                withAnimation(.easeOut(duration: 0.45)) {
                    confirmation = variantConfig.confirmationCopy(for: nextAction)
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

    let nextAction: String
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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Park") { _ = onPark(text) }
                        .disabled(!isValid)
                        .accessibilityIdentifier("confirmParkButton")
                }
            }
            .task { isFocused = true }
        }
        .presentationDetents([.medium, .large])
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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.visualVariantConfiguration) private var variantConfig
    @Query(sort: \ParkedIdea.createdAt, order: .reverse) private var ideas: [ParkedIdea]
    @State private var ideaToDelete: ParkedIdea?
    @State private var deleteFailed = false

    var body: some View {
        NavigationStack {
            Group {
                if ideas.isEmpty {
                    emptyState
                } else {
                    ideaList
                }
            }
            .navigationTitle("Parked ideas")
            .confirmationDialog(
                "Delete this parked idea?",
                isPresented: Binding(
                    get: { ideaToDelete != nil },
                    set: { if !$0 { ideaToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteSelectedIdea() }
                Button("Cancel", role: .cancel) { ideaToDelete = nil }
            }
            .alert("Couldn’t delete", isPresented: $deleteFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The parked idea is still present.")
            }
        }
    }

    private func deleteSelectedIdea() {
        guard let ideaToDelete else { return }
        modelContext.delete(ideaToDelete)
        do {
            try modelContext.save()
            self.ideaToDelete = nil
        } catch {
            modelContext.rollback()
            deleteFailed = true
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            if variantConfig.showsSophie {
                SophieMark(pose: .resting, size: 40)
                    .accessibilityHidden(true)
            }
            ContentUnavailableView(
                "Nothing parked",
                systemImage: "archivebox",
                description: Text("Ideas appear here only after you park them.")
            )
        }
    }

    private var ideaList: some View {
        List(ideas) { idea in
            VStack(alignment: .leading, spacing: 7) {
                Text(idea.text)
                    .font(.body)
                    .foregroundStyle(Color.nestInk)
                HStack {
                    Text(idea.state)
                        .font(.caption2.weight(.black))
                        .tracking(1)
                        .foregroundStyle(Color.nestSage)
                    Spacer()
                    Text(idea.createdAt, format: .dateTime.month().day().hour().minute())
                        .foregroundStyle(Color.nestInkMuted)
                }
            }
            .listRowBackground(
                variantConfig.variant == .control ? Color(.secondarySystemBackground) : Color.nestSurfaceRaised.opacity(0.5)
            )
            .swipeActions {
                Button("Delete", role: .destructive) {
                    ideaToDelete = idea
                }
            }
        }
        .scrollContentBackground(variantConfig.variant == .control ? .automatic : .hidden)
        .background(variantConfig.variant == .control ? Color.clear : Color.nestCanvas.opacity(0.3))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [NowContext.self, ParkedIdea.self], inMemory: true)
}
