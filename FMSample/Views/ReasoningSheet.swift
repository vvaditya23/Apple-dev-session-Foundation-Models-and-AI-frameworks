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
    @State private var reasoningSession: LanguageModelSession?

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
                    reasoningSession = switch operation {
                    case .actionItems:
                        try await loadActionItemsContent()
                    case .summary:
                        try await loadSummaryContent()
                    case .timeline:
                        try await loadTimelineContent()
                    }
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
    
    private func loadSummaryContent() async throws -> LanguageModelSession {
        generationState = .started
        let fullText = meetingItems.map { String($0.text.characters) }.joined(separator: "\n\n")

        let model = SystemLanguageModel(useCase: .general, guardrails: .permissiveContentTransformations)
        let instructions = "You are a helpful meeting assistant. Your task is to create a concise, neutral summary of the following meeting transcript and project-related documents. You MUST summarize the text in three paragraphs or less. You MUST be concise."
        let session = LanguageModelSession(model: model, instructions: instructions)
        let stream = session.streamResponse(to: fullText, generating: Summary.self)
        
        for try await partialResponse in stream {
            reasoningOutput = AttributedString(partialResponse.content.summary ?? "")
            generationState = .generating
        }
        generationState = .completed
        return session
    }
    
    @Generable
    struct ActionItems {
        @Guide(description: "A list of priority action items from the meeting", .maximumCount(10))
        var actionItems: [String]
    }
    
    private func loadActionItemsContent() async throws -> LanguageModelSession {
        generationState = .started
        let text = meetingItems
//            .filter {$0 is RecordingItem}
            .map { String($0.text.characters) }
            .joined(separator: "\n\n")

        let model = SystemLanguageModel.default
        let session = LanguageModelSession(
            model: model,
            instructions: "You are a helpful assistant. Your task is to extract action items from transcripts of team meetings. The text provided to you contains team meeting transcripts. You MUST return a list of priority action items based ONLY on the provided text."
        )
        
        let stream = session.streamResponse(to: text, generating: ActionItems.self)
        for try await partialActionItems in stream {
            reasoningOutput = partialActionItems.content.actionItems?.compactMap {
                AttributedString("• \($0)")
            }.joined(separator: "\n") ?? ""
            generationState = .generating
        }
        generationState = .completed
        return session
    }

    @Generable
    struct Timeline {
        @Guide(description: "Array of timeline items (milestones and tasks) extracted from the meeting transcripts")
        var timeline: [TimelineItem]

        @Guide(description: "Any important notes or ambiguities encountered during extraction")
        var extractionNotes: String?

        @Generable
        struct TimelineItem {
            @Guide(description: "Title of the item/milestone/task on the project timeline")
            var title: String

            @Guide(description: "Due date or timeframe for this item")
            var date: String

            @Guide(description: "Name of the individual responsible for this item, ONLY if specified")
            var owner: String?

            @Guide(description: "Current status of the timeline item, ONLY if mentioned in the transcripts, e.g. 'complete', 'in progress', 'blocked', 'planned'")
            var status: String?

            @Guide(description: "Priority of the timeline item, ONLY if mentioned")
            var priority: Priority?

            @Generable
            enum Priority {
                case critical
                case high
                case medium
                case low
                case unspecified
            }
        }
    }

    static let sampleTimeline = Timeline(
        timeline: [
            Timeline.TimelineItem(
                title: "Project kickoff",
                date: "April 1, 2026",
                owner: "Alice Johnson",
                status: "complete",
                priority: .medium
            ),
            Timeline.TimelineItem(
                title: "Share roadmap with design team",
                date: "May 2, 2026",
                owner: "Bob Smith",
                status: "in progress",
                priority: .medium
            ),
            Timeline.TimelineItem(
                title: "Present to leadership",
                date: "June 3, 2026",
                owner: "Claire White",
                status: "planned",
                priority: .high
            ),
            Timeline.TimelineItem(
                title: "Complete security review",
                date: "July 2026",
                owner: "Dana Lee",
                status: "planned",
                priority: .high
            )
        ],
        extractionNotes: ""
    )

    private func loadTimelineContent() async throws -> LanguageModelSession {
        let model = SystemLanguageModel(useCase: .general, guardrails: .permissiveContentTransformations)
        let session = LanguageModelSession(model: model, instructions: {
            """
            You are a project timeline extraction assistant. Your task is to analyze meeting transcripts and generate a structured project timeline containing milestones and tasks.
            INSTRUCTIONS:
            1. Extract all milestones, deliverables, and actionable tasks mentioned across the provided meeting transcripts
            2. For each item, identify:
               - Clear title/description of the milestone/task
               - Owner/assignee (individual person responsible)
               - Due date (explicit dates, relative dates like "next week", or inferred timeframes)
               - Status if mentioned (e.g., "in progress", "completed", "planned", "blocked")
               - Priority if mentioned (e.g., "high", "medium", "low", "critical")
            3. Only include information explicitly stated or reasonably inferred from the transcripts
            4. If a date is mentioned relatively (e.g., "next Friday", "in two weeks"), preserve it as stated
            5. If critical information is missing or unclear, note it in the appropriate field
            
            BASE YOUR RESPONSE SOLELY ON THE PROVIDED TRANSCRIPTS. Do not add assumptions or information not present in the text.
            If the text does not contain tasks or deliverables, say "There are no tasks nor timelines".

            Here is an example, but don't copy it:
            """
            Self.sampleTimeline
        })

        let text = meetingItems
//            .filter {$0 is RecordingItem || $0 is ScannedItem}
            .map { String($0.text.characters) }
            .joined(separator: "\n\n")
        
        let stream = session.streamResponse(to: text, generating: Timeline.self)
        
        for try await partialResponse in stream {
            guard let timeline = partialResponse.content.timeline else {
                reasoningOutput = ""
                continue
            }
            reasoningOutput = timeline.compactMap {
                guard let date = $0.date,
                      let title = $0.title
                    else { return nil }
                var details = [AttributedString(title, attributes: AttributeContainer().font(.body.bold()))]
                var secondLine: [AttributedString] = [AttributedString("📆 \(date)")]
                if let priority = $0.priority,
                   priority != .unspecified {
                    secondLine.append(AttributedString("🎯 \(priority)"))
                }
                if let owner = $0.owner {
                    secondLine.append(AttributedString("👤 \(owner)"))
                }
                details.append(secondLine.joined(separator: " • "))
                if let status = $0.status {
                    details.append(AttributedString(
                        status,
                        attributes: AttributeContainer().foregroundColor(.secondary))
                    )
                }
                return details.joined(separator: "\n")
            }.joined(separator: "\n\n") + AttributedString(
                "\n\n" + (partialResponse.content.extractionNotes ?? "n/a"),
                attributes: AttributeContainer().foregroundColor(.secondary).font(.caption.italic())
            )
            generationState = .generating
        }
        generationState = .completed
        return session
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
