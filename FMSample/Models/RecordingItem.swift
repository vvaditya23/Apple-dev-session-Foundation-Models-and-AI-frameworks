/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model class for meeting items that represent recordings and their transcription.
*/

import Foundation
import CoreGraphics
import FoundationModels
import ImagePlayground

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

    @Generable
    struct ImagePrompt {
        @Guide(description: "A simple description of an image that can be generated based on the meeting notes")
        var prompt: String
    }
    
    func suggestedImage() async throws -> CGImage? {
        let session = LanguageModelSession(model: SystemLanguageModel.default, instructions: "You are a helpful assistant that takes meeting notes. From those notes you MUST extract 3 or 4 terms that can be used to visualize key concepts in the notes by using Image Playground. You must only output a string that can be used by Image Playground to generate an image.")
        
        let answer = try await session.respond(to: String(text.characters), generating: ImagePrompt.self)
        let concept = ImagePlaygroundConcept.extracted(from: answer.content.prompt)
        let creator = try await ImageCreator()
        let imageSequence = creator.images(for: [concept], style: .sketch, limit: 1)
        
        for try await image in imageSequence {
            return image.cgImage
        }
        return nil
    }
}
