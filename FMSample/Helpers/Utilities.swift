/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Helper code for natural language operations.
*/

import NaturalLanguage

struct ChunkProcessor {
    let text: String
    let ranges: [Range<String.Index>]

    init(text: String) {
        self.text = text

        let tokenizer = NLTokenizer(unit: .paragraph)
        tokenizer.string = text
        ranges = tokenizer.tokens(for: text.startIndex ..< text.endIndex)
    }

    func process(operation: (String) async throws -> String) async throws -> String {
        try await ChunkProcessor.process(text, ranges: ranges, operation: operation)
    }

    static func process(
        _ string: String,
        ranges: [Range<String.Index>],
        operation: (String) async throws -> String
    ) async throws -> String {
        guard !ranges.isEmpty && !string.isEmpty else { throw ChunkProcessingError.empty }

        // Try to process the entire range
        let fullRange = ranges.first!.lowerBound ..< ranges.last!.upperBound
        let fullText = String(string[fullRange])

        do {
            // If the text is larger that 3 times the context window size, don't even bother
            guard fullText.count < 4096 * 3 else { throw ChunkProcessingError.tooLarge }

            return try await operation(fullText)
        } catch {
            // If we only have one range, we can't subdivide further
            guard ranges.count > 1 else {
                throw error
            }

            // Split ranges in half and process recursively
            let midpoint = ranges.count / 2
            let firstHalf = Array(ranges[..<midpoint])
            let secondHalf = Array(ranges[midpoint...])

            let firstResult = try await process(string, ranges: firstHalf, operation: operation)
            let secondResult = try await process(string, ranges: secondHalf, operation: operation)

            return firstResult + "\n" + secondResult
        }
    }
}

enum ChunkProcessingError: Error {
    case empty
    case tooLarge
}
