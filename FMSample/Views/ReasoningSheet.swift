/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View showing the result of reasoning on the available material for timeline extraction, summarization, etc..
*/

import SwiftUI
import FoundationModels

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
            .task {
                do {
                    try await loadSummaryContent()
                } catch let error as LanguageModelSession.GenerationError {
                    switch error {
                    case .guardrailViolation:
                        print("Generation was blocked due to safety guardrails: \(error)")
                    default:
                        print("Generation error: \(error)")
                    }
                } catch {
                    print("Error: \(error)")
                }
            }
        }
        .adaptiveSheetFrame()
    }

    @Generable
    struct Summary {
        var summary: String
    }
    
    private func loadSummaryContent() async throws {
        generationState = .started
        let fullText = meetingItems.map { String($0.text.characters) }.joined(separator: "\n\n")
        let model = SystemLanguageModel.default
        let instructions = "You are a helpful meeting assistant. Your task is to create a concise, neutral summary of the following meeting transcript and project-related documents. You MUST summarize the text in three paragraphs or less. You MUST be concise."
        let session = LanguageModelSession(model: model, instructions: instructions)
        let stream = session.streamResponse(to: fullText, generating: Summary.self)
        
        for try await partialResponse in stream {
            reasoningOutput = AttributedString(partialResponse.content.summary ?? "")
            generationState = .generating
        }
        generationState = .completed
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
