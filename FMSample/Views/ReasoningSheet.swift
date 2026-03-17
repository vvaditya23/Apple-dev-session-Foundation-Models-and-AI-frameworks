/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View showing the result of reasoning on the available material for timeline extraction, summarization, etc..
*/

import SwiftUI

enum ReasoningSheetOperation: Identifiable {
    case actionItems
    case summary
    case timeline

    var id: Self { self }
}

enum AnswerGenerationState {
    case started
    case generating
    case completed
}

struct ReasoningSheet: View {
    @Environment(\.dismiss) private var dismiss
    let meetingItems: [MeetingItem]
    let operation: ReasoningSheetOperation

    @State private var reasoningOutput: AttributedString = ""
    @State private var generationState: AnswerGenerationState = .started
    @State private var feedbackState: FeedbackState = .none

    var body: some View {
        NavigationStack {
            VStack {
                AsyncContentView(generationState: generationState) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(reasoningOutput)
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
            .navigationTitle(operation.sheetTitle)
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

extension ReasoningSheetOperation {
    var symbolName: String {
        switch self {
            case .actionItems: "Action Items"
            case .summary: "Summary"
            case .timeline: "Timeline"
        }
    }
    var sheetTitle: String {
        switch self {
            case .actionItems: "Action Items"
            case .summary: "Summary"
            case .timeline: "Timeline"
        }
    }
}
