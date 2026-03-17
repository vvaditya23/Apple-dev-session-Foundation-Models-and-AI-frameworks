/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model class for meeting items that represent document / whiteboard scans.
*/

import Foundation

class ScannedItem: MeetingItem {
    override class var symbolName: String { "text.viewfinder" }
    override class var accessibilityLabel: String { "Scanned Document" }
}
