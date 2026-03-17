/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View that shows the document scanner.
*/

#if os(iOS)

import SwiftUI

struct DocumentScannerView: View {
    @Binding var isPresented: Bool
    var onScanComplete: () -> Void

    var body: some View {
        VStack {
            Text("placeholder")
                .padding()
            Spacer()
            Button("Done") {
                onScanComplete()
                isPresented = false
            }
        }
    }
}

#endif
