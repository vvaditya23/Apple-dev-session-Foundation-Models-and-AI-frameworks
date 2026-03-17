/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Reusable view for handling async content loading states (loading, success).
*/

import SwiftUI

struct AsyncContentView<Content: View>: View {
    let generationState: AnswerGenerationState
    @ViewBuilder let content: () -> Content

    var body: some View {
        if generationState == .started {
            Spacer()
            ProgressView("Thinking…")
                .padding()
        } else {
            content()
        }
    }
}
