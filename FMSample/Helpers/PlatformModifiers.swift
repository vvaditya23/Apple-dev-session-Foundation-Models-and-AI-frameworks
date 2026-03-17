/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Platform-specific view modifiers for iOS and macOS.
*/

import SwiftUI

extension View {
    /// Applies platform-appropriate sheet presentation styling
    @ViewBuilder
    func adaptiveSheet() -> some View {
        #if os(iOS)
        self
            .presentationDetents([.medium, .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .large))
            .presentationDragIndicator(.visible)
        #else
        self
            .presentationSizing(.fitted)
        #endif
    }

    /// Applies platform-appropriate frame constraints for modal sheets
    @ViewBuilder
    func adaptiveSheetFrame() -> some View {
        #if os(macOS)
        self.frame(minWidth: 500, minHeight: 400)
        #else
        self
        #endif
    }

    /// Applies platform-appropriate frame constraints for feedback dialog
    @ViewBuilder
    func adaptiveFeedbackDialogFrame() -> some View {
        #if os(macOS)
        self.frame(minWidth: 500)
        #else
        self
        #endif
    }

    /// Platform-appropriate progress view sizing
    @ViewBuilder
    func adaptiveProgressView() -> some View {
        #if os(macOS)
        self.controlSize(.small)
        #else
        self
        #endif
    }
}

/// Platform-appropriate dismiss button for toolbars
struct AdaptiveDismissButton: View {
    let action: () -> Void

    var body: some View {
        #if os(macOS)
        Button("Done", action: action)
        #else
        Button("Done", systemImage: "xmark", action: action)
        #endif
    }
}
