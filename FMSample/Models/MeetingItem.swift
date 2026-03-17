/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Base model class for meeting items.
*/

import Foundation

@Observable
class MeetingItem: Identifiable, MeetingItemRepresentable {
    let id: UUID
    var title: String
    var text: AttributedString
    var url: URL?
    var isComplete: Bool

    class var symbolName: String { fatalError("Subclasses must override symbolName.") }
    class var accessibilityLabel: String { fatalError("Subclasses must override accessibilityLabel.") }

    init(title: String, text: AttributedString, url: URL? = nil, isComplete: Bool = false) {
        self.title = title
        self.text = text
        self.url = url
        self.isComplete = isComplete
        self.id = UUID()
    }
}

protocol MeetingItemRepresentable {
    static var symbolName: String { get }
}

extension MeetingItem {
    func textBrokenUpByLines() -> AttributedString {
        guard url != nil else {
            print("url was nil")
            return text
        }

        var final: AttributedString = ""
        var working: AttributedString = ""
        let copy = text
        copy.runs.forEach { run in
            if copy[run.range].characters.contains(".") {
                working.append(copy[run.range])
                final.append(working)
                final.append(AttributedString("\n\n"))
                working = ""
            } else {
                if working.characters.isEmpty {
                    let newText = copy[run.range].characters
                    let attributes = run.attributes
                    let trimmed = newText.trimmingPrefix(" ")
                    let newAttributed = AttributedString(trimmed, attributes: attributes)
                    working.append(newAttributed)
                } else {
                    working.append(copy[run.range])
                }
            }
        }

        if final.characters.isEmpty {
            return working
        }

        return final
    }
}

extension MeetingItem: Equatable {
    static func == (lhs: MeetingItem, rhs: MeetingItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension MeetingItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
