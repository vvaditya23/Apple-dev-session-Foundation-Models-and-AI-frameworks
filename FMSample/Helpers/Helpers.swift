/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Helper code for UI and transcription.
*/

import Foundation

extension Array where Element == AttributedString {
    func joined(separator: AttributedString = AttributedString()) -> AttributedString {
        isEmpty ? "" : self.dropFirst().reduce(into: self[0]) { result, element in
            result.append(separator + element)
        }
    }

    func joined(separator: String) -> AttributedString {
        joined(separator: AttributedString(separator))
    }
}
