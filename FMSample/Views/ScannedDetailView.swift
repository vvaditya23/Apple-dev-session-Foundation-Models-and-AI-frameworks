/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View showing meeting items that represent document / whiteboard scans.
*/

import SwiftUI

struct ScannedDetailView: View {
    @Binding var meetingItem: ScannedItem

    init(item: Binding<ScannedItem>) {
        _meetingItem = item
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(meetingItem.text)
                    .padding()
                Spacer()
            }
        }
        .navigationTitle(meetingItem.title)
    }
}
