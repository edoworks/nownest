import SwiftData
import SwiftUI

struct DeferredReviewSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeferredReviewCoordinator.self) private var coordinator
    @State private var confirmingDiscard = false
    @State private var saveFailed = false

    let idea: ParkedIdea
    let onDiscarded: () -> Void
    let onAddUpdate: () -> Void

    var body: some View {
        Section("AI review") {
            if let message = coordinator.storageError {
                Text(message).font(.subheadline)
            }
            if idea.reviewDecision == "kept" {
                Label("Kept for later", systemImage: "checkmark.circle")
                    .accessibilityIdentifier("reviewKeptState")
            }

            if let status = idea.deferredReviewStatus {
                if !idea.savedUpdates.isEmpty && (status == .queued || status.isProcessing) {
                    Label("Update saved", systemImage: "checkmark.circle")
                        .accessibilityIdentifier("updateSavedState")
                }
                if status.isProcessing && idea.reviewDecision == nil {
                    HStack {
                        ProgressView()
                        Text(status.label)
                            .accessibilityIdentifier("reviewProcessingState")
                    }
                } else if idea.reviewDecision == nil && (status != .ready || !idea.hasCurrentReview) {
                    Text(status == .ready && !idea.hasCurrentReview ? DeferredReviewStatus.stale.label : status.label)
                        .font(.subheadline.weight(.semibold))
                        .accessibilityIdentifier("reviewStatus")
                }

                if status == .ready && idea.hasCurrentReview {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(idea.reviewCategory ?? "Needs clarification")
                            .font(.headline)
                            .accessibilityIdentifier("reviewCategory")
                        Text(idea.reviewReason ?? "")
                            .accessibilityIdentifier("reviewReason")
                        Text("Uncertainty: \(idea.reviewUncertainty ?? "Context may be missing.")")
                            .font(.subheadline)
                            .accessibilityIdentifier("reviewUncertainty")
                    }
                    Text("AI suggestion · reviewed and critiqued by the same on-device model. This isn’t independent verification.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let message = idea.reviewMessage, idea.reviewDecision == nil {
                    Text(message)
                        .font(.subheadline)
                        .accessibilityIdentifier("reviewMessage")
                }

                if status != .ready, let previous = idea.savedReviewHistory.last {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Previous review")
                            .font(.subheadline.weight(.semibold))
                            .accessibilityIdentifier("previousReview")
                        Text(previous.category).font(.subheadline.weight(.semibold))
                        Text(previous.reason).font(.subheadline)
                        Text("Uncertainty: \(previous.uncertainty)")
                            .font(.caption)
                    }
                }

                if status == .queued && idea.reviewDecision == nil {
                    Text("Runs while NowNest is active. You can decide without waiting.")
                        .font(.caption)
                }
            } else {
                Text("This idea hasn’t been reviewed. You can decide yourself or request an on-device review.")
                    .font(.subheadline)
            }

            Button("Add update", systemImage: "plus.bubble") {
                onAddUpdate()
            }
            .accessibilityIdentifier("addUpdateButton")

            if !idea.savedUpdates.isEmpty {
                DisclosureGroup("Your updates (\(idea.savedUpdates.count))") {
                    ForEach(idea.savedUpdates) { update in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(update.text)
                            Text(update.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityIdentifier("savedUpdates")
            }

            if idea.deferredReviewStatus == .ready && !idea.savedReviewHistory.isEmpty {
                DisclosureGroup("Earlier reviews (\(idea.savedReviewHistory.count))") {
                    ForEach(idea.savedReviewHistory.reversed()) { review in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(review.category).font(.subheadline.weight(.semibold))
                            Text(review.reason)
                            Text("Uncertainty: \(review.uncertainty)")
                                .font(.caption)
                        }
                    }
                }
            }

            if idea.reviewDecision == nil {
                Button("Keep for later", systemImage: "archivebox") {
                    do { try coordinator.keep(idea, in: modelContext) }
                    catch { saveFailed = true }
                }
                .accessibilityIdentifier("keepIdeaButton")
            }
            Button("Discard idea", systemImage: "archivebox", role: .destructive) {
                confirmingDiscard = true
            }
            .accessibilityIdentifier("discardIdeaButton")

            if idea.deferredReviewStatus == .ready && idea.hasCurrentReview {
                DisclosureGroup("Review before critique") {
                    Text(idea.reviewDraft ?? "")
                }
            }

            if idea.reviewDecision == nil && (coordinator.storageError != nil || (idea.deferredReviewStatus?.isProcessing != true && idea.deferredReviewStatus != .queued)) {
                Button(idea.deferredReviewStatus == nil ? "Review on device" : "Retry review") {
                    do { try coordinator.retry(idea, in: modelContext) }
                    catch { saveFailed = true }
                }
                .accessibilityIdentifier("retryReviewButton")
            }

            Text("Only you can keep, resume, or discard. Your original thought and interrupted context stay saved on this device.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .alert("Discard this idea?", isPresented: $confirmingDiscard) {
            Button("Discard idea", role: .destructive) {
                do {
                    try NowNestStore.abandon(idea, in: modelContext)
                    onDiscarded()
                } catch { saveFailed = true }
            }
            .accessibilityIdentifier("confirmDiscardIdeaButton")
            Button("Cancel", role: .cancel) {}
                .accessibilityIdentifier("cancelDiscardIdeaButton")
        } message: {
            Text("It will leave Saved for later. The original thought and interrupted context will remain stored on this device.")
        }
        .alert("Couldn’t save your decision", isPresented: $saveFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your original idea is unchanged. Please try again.")
        }
    }
}

struct AddIdeaUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(DeferredReviewCoordinator.self) private var coordinator
    @State private var draft = ""
    @State private var errorMessage: String?

    let idea: ParkedIdea

    var body: some View {
        NavigationStack {
            Form {
                Section("What changed?") {
                    TextField("Add context for a fresh review", text: $draft, axis: .vertical)
                        .lineLimit(4...8)
                        .accessibilityIdentifier("ideaUpdateField")
                    Text("\(draft.count)/500 characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Your original thought stays unchanged. The new review will consider this update alongside your earlier context.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("updateError")
                }
            }
            .navigationTitle("Add update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & review") {
                        do {
                            try coordinator.addUpdate(draft, to: idea, in: modelContext)
                            dismiss()
                        } catch DeferredReviewError.inputTooLong {
                            errorMessage = "The saved context is too long for another short on-device review."
                        } catch {
                            errorMessage = "Couldn’t save this update. Your original thought is unchanged."
                        }
                    }
                    .disabled(NowNestRules.normalized(draft) == nil || draft.count > 500)
                    .accessibilityIdentifier("saveUpdateButton")
                }
            }
        }
    }
}
