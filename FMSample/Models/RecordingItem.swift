/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model class for meeting items that represent recordings and their transcription.
*/

import Foundation
import CoreGraphics
import FoundationModels

@Observable
class RecordingItem: MeetingItem {
    override class var symbolName: String { "waveform" }
    override class var accessibilityLabel: String { "Recording" }

    var image: CGImage?
    var isGeneratingImage = false

    static var emptyRecording: RecordingItem {
        RecordingItem(title: "New Recording", text: "")
    }

    @Generable
    struct RecordingTitle {
        var title: String
    }

    func suggestedTitle() async throws -> String? {
        // Note: Capitalization matters (all caps == emphasis)
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: "You are an expert headline writer who takes meeting notes. From those notes you MUST generate most relevant title, with no other text."
        )

        let answer = try await session.respond(
            to: String(text.characters),
            generating: RecordingTitle.self
        )
        return answer.content.title.trimmingCharacters(in: .punctuationCharacters)
    }

    func suggestedImage() async throws -> CGImage? {
        nil
    }
}
