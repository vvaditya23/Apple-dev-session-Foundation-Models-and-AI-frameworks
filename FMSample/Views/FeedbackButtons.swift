/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Thumbs up/down controls for providing feedback.
*/

import SwiftUI

enum FeedbackState {
    case none
    case thumbsUp
    case thumbsDown
}

struct FeedbackButtons: View {
    @Binding var feedbackState: FeedbackState

    @State private var showingFeedbackDialog = false

    init(
        feedbackState: Binding<FeedbackState>
    ) {
        self._feedbackState = feedbackState
    }

    var body: some View {
        HStack(spacing: 8) {
            // Thumbs up button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    feedbackState = feedbackState == .thumbsUp ? .none : .thumbsUp
                }
                handleFeedback(feedback: feedbackState)
            } label: {
                Image(systemName: feedbackState == .thumbsUp ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .foregroundStyle(feedbackState == .thumbsUp ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Thumbs up")
            .accessibilityHint("Mark this output as helpful")

            // Thumbs down button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    feedbackState = feedbackState == .thumbsDown ? .none : .thumbsDown
                }
                handleFeedback(feedback: feedbackState)
            } label: {
                Image(systemName: feedbackState == .thumbsDown ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .foregroundStyle(feedbackState == .thumbsDown ? .red : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Thumbs down")
            .accessibilityHint("Mark this output as not helpful")
        }
        .sheet(isPresented: $showingFeedbackDialog) {
            FeedbackDialogView() { explanation in

            }
        }
    }

    private func handleFeedback(feedback: FeedbackState) {
        switch feedback {
            case .thumbsDown:
                // Request more details before submitting feedback
                showingFeedbackDialog = true

            case .thumbsUp:
                // Submit positive feedback without user interaction
                break

            default:
                break
        }
    }
}

struct FeedbackDialogView: View {
    @Environment(\.dismiss) private var dismiss

    let onSubmit: (String) -> Void

    @State private var selectedCategory: Int = 1
    @State private var explanation: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Issue Category", selection: $selectedCategory) {
                    Text("One").tag(1)
                    Text("Two").tag(2)
                }
                .pickerStyle(.menu)

#if os(iOS)
                Section("Explanation") {
                    TextField("Please describe the issue", text: $explanation, axis: .vertical)
                        .lineLimit(5...10)
                }
#else
                TextField("Description", text: $explanation, axis: .vertical)
                    .lineLimit(5...10)
#endif
            }
            .padding()
            .navigationTitle("Report a Concern")
            .adaptiveFeedbackDialogFrame()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit Report") {
                        onSubmit(explanation)
                        dismiss()
                    }
                    .disabled(explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .adaptiveSheet()
    }
}
