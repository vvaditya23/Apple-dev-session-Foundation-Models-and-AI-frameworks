/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View showing meeting items that represent project documents.
*/

import SwiftUI

struct DocumentDetailView: View {
    @Binding var meetingItem: DocumentItem

    init(item: Binding<DocumentItem>) {
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
