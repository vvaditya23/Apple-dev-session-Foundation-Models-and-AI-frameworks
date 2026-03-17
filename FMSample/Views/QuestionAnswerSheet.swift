/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View that displays answers to user questions.
*/

import SwiftUI
import FoundationModels

struct QuestionAnswerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let meetingItems: [MeetingItem]
    let question: String

    @State private var session: LanguageModelSession?

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
            .task {
                if session == nil {
                    let model = SystemLanguageModel(useCase: .general)
                    session = LanguageModelSession(
                        model: model,
                        instructions: """
                        You are a helpful office team member who takes meeting notes and collects documents related to the team's projects. Answer the user's question below, based ONLY on the provided information.
                        Important: if the user's question is unrelated to the provided information, say "Sorry, I can't answer that question".
                        """
                    )
                }
                
                do {
                    try await fetchAnswer()
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
    struct Response {
        @Guide(description: "An exact quote containing the answer from the source material")
        var citation: String

        @Guide(description: "A brief answer to the question")
        var answer: String

        @Guide(description: "Whether it was not possible to answer the question")
        var insufficinetInformation: Bool
    }

    private func fetchAnswer() async throws {
        defer { generationState = .completed }
        guard let session else { return }
        
        let text = meetingItems
            .map { String($0.text.characters) }
            .joined(separator: "\n\n")

        // Prompt is passed in the closure
        let stream = session.streamResponse(generating: Response.self) {
            "Question \(question)"
            "This is all the information that you can use to answer the question:"
            text
        }
        
        for try await partialAnswer in stream {
            if partialAnswer.content.insufficinetInformation == true {
                answer = "I couldn't find enough information to answer this"
            } else {
                var answerText = AttributedString(partialAnswer.content.answer ?? "")
                
                if let citation = partialAnswer.content.citation,
                   !citation.isEmpty {
                    var citationText = AttributedString("\n\nBecause “\(citation)”")
                    citationText.font = .caption.italic()
                    citationText.foregroundColor = .secondary
                    answerText.append(citationText)
                }

                answer = answerText
            }
            generationState = .generating
        }
    }
}
