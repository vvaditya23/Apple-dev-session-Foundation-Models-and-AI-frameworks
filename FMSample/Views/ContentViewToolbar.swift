/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Toolbar content for the main ContentView.
*/

import SwiftUI
#if os(iOS)
import AVFoundation
#endif

struct ContentViewToolbar: ToolbarContent {
    @Binding var meetingItems: [MeetingItem]
    @Binding var selection: MeetingItem?
    @Binding var reasoningSheetOperation: ReasoningSheetOperation?
    @Binding var isImportingFile: Bool
    @Binding var isScanningDocument: Bool

    let isQuestionFieldFocused: Bool
    let toolbarActionButtons: AnyView
    let questionField: AnyView

    var body: some ToolbarContent {
        ToolbarItem {
            Menu {
                Button("New Recording", systemImage: "record.circle") {
                    let newItem = RecordingItem.emptyRecording
                    meetingItems.append(newItem)
                    selection = newItem
                }
                Button("Add File", systemImage: "text.badge.plus") {
                    isImportingFile = true
                }
#if os(iOS)
                Button("Scan Document", systemImage: "document.viewfinder") {
                    isScanningDocument = true
                }
#endif
            } label: {
                Label("Add Item", systemImage: "plus")
            }
        }

#if os(iOS)
        ToolbarItemGroup(placement: .bottomBar) {
            if !isQuestionFieldFocused {
                toolbarActionButtons
                Spacer()
            }
            questionField
        }
#else
        ToolbarItemGroup {
            ControlGroup {
                toolbarActionButtons
            }
            .controlGroupStyle(.navigation)
        }
#endif
    }
}
