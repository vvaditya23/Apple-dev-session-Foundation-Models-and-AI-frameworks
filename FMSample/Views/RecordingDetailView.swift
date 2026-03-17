/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View showing meeting items that represent recordings and their transcription.
*/

import Foundation
import SwiftUI
import AVFoundation

struct RecordingDetailView: View {
    @Binding var meetingItem: RecordingItem
    @State var isRecording = false

    @State var recorder: Recorder
    @State var speechTranscriber: SpokenWordTranscriber

    init(item: Binding<RecordingItem>) {
        _meetingItem = item
        let transcriber = SpokenWordTranscriber(meetingItem: item)
        recorder = Recorder(transcriber: transcriber, meetingItem: item)
        speechTranscriber = transcriber
    }

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if !meetingItem.isComplete {
                    if isRecording {
                        liveRecordingView
                    } else {
                        Text("To start recording, press \(Image(systemName: "record.circle")).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    transcriptView
                }
            }
            Spacer()
        }
        .padding(20)
        .navigationTitle(meetingItem.title)
        .toolbar {
            if !meetingItem.isComplete {
                ToolbarItem {
                    Button {
                        handleRecordingButtonTap()
                    } label: {
                        if isRecording {
                            Label("Stop", systemImage: "pause.fill").tint(.red)
                        } else {
                            Label("Record", systemImage: "record.circle").tint(.red)
                        }
                    }
                }
            }
        }
        .onChange(of: isRecording) { oldValue, newValue in
            guard newValue != oldValue else { return }
            if newValue {
                Task {
                    do {
                        try await recorder.record()
                    } catch {
                        print("could not record: \(error)")
                    }
                }
            } else {
                Task {
                    do {
                        try await recorder.stopRecording()
                    } catch {
                        print("error after recording: \(error)")
                    }
                }
            }
        }
        .onDisappear {
            // Ensure clean shutdown when view is destroyed
            Task {
                if isRecording {
                    try? await recorder.stopRecording()
                }
            }
        }
    }

    @ViewBuilder
    var liveRecordingView: some View {
        Text(speechTranscriber.finalizedTranscript + speechTranscriber.volatileTranscript)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var transcriptView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let image = meetingItem.image {
                    Image(image, scale: 1.0, label: Text("A sketch representing the topic of the meeting."))
                        .resizable()
                        .scaledToFit()
                } else if meetingItem.isGeneratingImage {
                    ProgressView("Generating image…")
                        .frame(maxWidth: .infinity)
                }
                Text(meetingItem.textBrokenUpByLines())
                    .font(.body)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func handleRecordingButtonTap() {
        isRecording.toggle()
    }
}
