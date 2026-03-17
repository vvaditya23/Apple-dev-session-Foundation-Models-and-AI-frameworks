/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The app's main view.
*/

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selection: MeetingItem?

    @State private var isImportingFile = false
    @State private var importedFileURL: URL?

    @State private var questionText = ""
    @FocusState private var isQuestionFieldFocused: Bool

    @State private var iconWidth: CGFloat?

    @State private var reasoningSheetOperation: ReasoningSheetOperation?

    @State private var isShowingQuestionSheet = false
    @State private var currentQuestion = ""

    @State private var isScanningDocument = false

    @State private var meetingItems: [MeetingItem] = []

    init() {}

    var body: some View {
        NavigationSplitView {
            Group {
                if meetingItems.isEmpty {
                    emptyView
                        .dropDestination(for: URL.self) { items, location in
                            return handleDrop(items: items)
                        }
                } else {
                    List(selection: $selection) {
                        ForEach(meetingItems) { item in
                            NavigationLink(value: item) {
                                listRowView(for: item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .deleteDisabled(false)
#if os(macOS)
                    .onDeleteCommand {
                        deleteSelectedItem()
                    }
#endif
                    .dropDestination(for: URL.self) { items, location in
                        return handleDrop(items: items)
                    }
                    .navigationTitle("Meeting Items")
                }
            }
            .toolbar {
                ContentViewToolbar(
                    meetingItems: $meetingItems,
                    selection: $selection,
                    reasoningSheetOperation: $reasoningSheetOperation,
                    isImportingFile: $isImportingFile,
                    isScanningDocument: $isScanningDocument,
                    isQuestionFieldFocused: isQuestionFieldFocused,
                    toolbarActionButtons: AnyView(toolbarActionButtons),
                    questionField: AnyView(questionField)
                )
            }
#if os(macOS)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                questionField
                    .glassEffect()
                    .padding(8)
            }
#endif
            .navigationSplitViewColumnWidth(min: 250, ideal: 320, max: 450)
        } detail: {
            if let selection {
                detailView(for: selection)
            } else if !meetingItems.isEmpty {
                Text("Select an item")
            }
        }
        .sheet(item: $reasoningSheetOperation) { operation in
            ReasoningSheet(meetingItems: meetingItems, operation: operation)
        }
        .sheet(isPresented: $isShowingQuestionSheet) {
            QuestionAnswerSheet(meetingItems: meetingItems, question: currentQuestion)
                .adaptiveSheet()
        }
#if os(iOS)
        .fullScreenCover(isPresented: $isScanningDocument) {
            DocumentScannerView(isPresented: $isScanningDocument) { scan in
                let newItem = ScannedItem(scan: scan)
                meetingItems.append(newItem)
                selection = newItem
            }
            .ignoresSafeArea()
        }
#endif
        .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: DocumentItem.allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let fileURL = urls.first {
                    let newItem = DocumentItem(fileURL: fileURL, isSecurityScoped: true)
                    meetingItems.append(newItem)
                    selection = newItem
                }
            case .failure:
                break
            }
        }
        .background(
            IconWidthCalculator(iconWidth: $iconWidth)
        )
    }

    @ViewBuilder
    private var toolbarActionButtons: some View {
        Button("Action Items", systemImage: "list.bullet") {
            reasoningSheetOperation = .actionItems
        }
        .disabled(meetingItems.isEmpty)
        .accessibilityLabel("Show action items")
        .accessibilityHint("Extract priority action items from meeting content")

        Button("Summary", systemImage: "text.line.2.summary") {
            reasoningSheetOperation = .summary
        }
        .disabled(meetingItems.isEmpty)
        .accessibilityLabel("Create summary")
        .accessibilityHint("Create a concise summary of meeting content")

        Button("Timeline", systemImage: "calendar.day.timeline.leading") {
            reasoningSheetOperation = .timeline
        }
        .disabled(meetingItems.isEmpty)
        .accessibilityLabel("Generate timeline")
        .accessibilityHint("Extract project timeline and milestones from meeting content")
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Meeting Items")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add a recording, document, or scanned image to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

#if os(macOS)
            dragAndDropView
#else
            if UIDevice.current.userInterfaceIdiom == .pad {
                dragAndDropView
            }
#endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false) // Allow drag events to pass through to the List
    }

    private var dragAndDropView: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.doc")
                .foregroundStyle(.secondary)
            Text("Or drag and drop files here")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var questionField: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundStyle(.secondary)

            TextField("Ask a question…", text: $questionText)
                .textFieldStyle(.plain)
                .focused($isQuestionFieldFocused)
                .submitLabel(.send)
                .onSubmit {
                    askQuestion(questionText)
                }

            if isQuestionFieldFocused && !questionText.isEmpty {
                Button(action: {
                    questionText = ""
                    isQuestionFieldFocused = false
                }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
#if os(macOS)
        .padding(.horizontal)
        .padding(.vertical, 8)
#else
        .padding(.horizontal, 8)
        .frame(
            minWidth: 200,
            idealWidth: isQuestionFieldFocused ? 400 : 300,
            maxWidth: isQuestionFieldFocused ? 500 : 400
        )
#endif
        .animation(.easeInOut(duration: 0.2), value: isQuestionFieldFocused)
        .disabled(meetingItems.isEmpty)
    }

    @ViewBuilder
    private func listRowView(for item: MeetingItem) -> some View {
        HStack {
            Image(systemName: type(of: item).symbolName)
                .frame(width: iconWidth, alignment: .center)
            Text(item.title)
            Spacer()
        }
    }

    @ViewBuilder
    private func detailView(for item: MeetingItem) -> some View {
        switch item {
            case let r as RecordingItem:
                RecordingDetailView(item: binding(for: r))
                    .id(r.id)
            case let d as DocumentItem:
                DocumentDetailView(item: binding(for: d))
                    .id(d.id)
            case let s as ScannedItem:
                ScannedDetailView(item: binding(for: s))
                    .id(s.id)
            default:
                Text("Invalid item")
        }
    }

    private func binding<T: MeetingItem>(for item: T) -> Binding<T> {
        Binding(
            get: {
                guard let index = meetingItems.firstIndex(where: { $0.id == item.id }),
                      let typedItem = meetingItems[index] as? T else {
                    return item
                }
                return typedItem
            },
            set: { newValue in
                guard let index = meetingItems.firstIndex(where: { $0.id == item.id }) else {
                    return
                }
                meetingItems[index] = newValue
            }
        )
    }

    private func deleteItems(at offsets: IndexSet) {
        // If the selected item is being deleted, clear the selection
        if let selection = selection,
           let index = meetingItems.firstIndex(where: { $0.id == selection.id }),
           offsets.contains(index) {
            self.selection = nil
        }

        meetingItems.remove(atOffsets: offsets)
    }

    private func deleteSelectedItem() {
        guard let selection = selection,
              let index = meetingItems.firstIndex(where: { $0.id == selection.id }) else {
            return
        }

        self.selection = nil
        meetingItems.remove(at: index)
    }

    private func askQuestion(_ prompt: String) {
        guard !prompt.isEmpty else { return }
        currentQuestion = prompt
        isShowingQuestionSheet = true
        questionText = ""
        isQuestionFieldFocused = false
    }

    private func handleDrop(items: [URL]) -> Bool {
        var itemsWereDropped = false
        for url in items {
            do {
                // Check if the file type is supported
                let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey])

                if let contentType = resourceValues?.contentType,
                   DocumentItem.allowedTypes.contains(where: { contentType.conforms(to: $0) }) {
                    let item = DocumentItem(fileURL: url, isSecurityScoped: false)
                    meetingItems.append(item)
                    if !itemsWereDropped {
                        itemsWereDropped = true
                        selection = item
                    }
                }
            }
        }
        return itemsWereDropped
    }
}

// Helper view to calculate the maximum width of all icons
private struct IconWidthCalculator: View {
    @Binding var iconWidth: CGFloat?

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: RecordingItem.symbolName)
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: IconWidthPreferenceKey.self, value: geometry.size.width)
                })
            Image(systemName: DocumentItem.symbolName)
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: IconWidthPreferenceKey.self, value: geometry.size.width)
                })
            Image(systemName: ScannedItem.symbolName)
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: IconWidthPreferenceKey.self, value: geometry.size.width)
                })
        }
        .hidden()
        .onPreferenceChange(IconWidthPreferenceKey.self) { width in
            iconWidth = width
        }
    }
}

private struct IconWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// An extension to assist with previewing content with meeting items.
extension ContentView {
    fileprivate init(meetingItems: [MeetingItem] = []) {
        _meetingItems = State(initialValue: meetingItems)
    }
}

#Preview("ContentView") {
    let sampleRecordings = [
        RecordingItem(
            title: "Team standup",
            text: "Discussed project progress and upcoming deadlines."
        ),
        RecordingItem(
            title: "UI review",
            text: "Discussion on changes to custom controls."
        ),
        RecordingItem(
            title: "Call: week of Nov 3rd",
            text: "Update from the remote team."
        )
    ]

    let sampleDocument = DocumentItem(fileURL: nil)
    sampleDocument.title = "Project requirements"
    sampleDocument.text = "Requirements document for the new feature."

    return ContentView(meetingItems: sampleRecordings + [sampleDocument])
}
