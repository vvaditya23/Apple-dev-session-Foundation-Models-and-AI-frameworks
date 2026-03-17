/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View that displays answers to user questions.
*/

import SwiftUI

struct QuestionAnswerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let meetingItems: [MeetingItem]
    let question: String

    @State private var answer: AttributedString = ""
    @State private var generationState: AnswerGenerationState = .started
    @State private var feedbackState: FeedbackState = .none

    var body: some View {
        NavigationStack {
            VStack {
                AsyncContentView(generationState: generationState) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(question)
                                .font(.headline)
                                .padding()
                            Text(answer)
                                .padding()
                            if generationState == .completed {
                                HStack {
                                    Spacer()
                                    FeedbackButtons(feedbackState: $feedbackState)
                                        .padding()
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("Q&A")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    AdaptiveDismissButton { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    if generationState == .generating {
                        ProgressView()
                            .adaptiveProgressView()
                    }
                }
            }
        }
        .adaptiveSheetFrame()
    }
}
