/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Audio input code.
*/

import Foundation
import AVFoundation
import SwiftUI

class Recorder {
    private var outputContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation? = nil
    private let audioEngine: AVAudioEngine
    private let transcriber: SpokenWordTranscriber

    var meetingItem: Binding<RecordingItem>

    var file: AVAudioFile?
    private let url: URL

    init(transcriber: SpokenWordTranscriber, meetingItem: Binding<RecordingItem>) {
        audioEngine = AVAudioEngine()
        self.transcriber = transcriber
        self.meetingItem = meetingItem
        self.url = FileManager.default.temporaryDirectory
            .appending(component: UUID().uuidString)
            .appendingPathExtension(for: .wav)
    }

    func record() async throws {
        meetingItem.url.wrappedValue = url
        guard await isAuthorized() else {
            print("user denied mic permission")
            return
        }
#if os(iOS)
        try setUpAudioSession()
#endif
        try await transcriber.setUpTranscriber()

        for await input in try await audioStream() {
            try await transcriber.streamAudioToTranscriber(input)
        }
    }

    func stopRecording() async throws {
        audioEngine.stop()
        meetingItem.isComplete.wrappedValue = true

        try await transcriber.finishTranscribing()

        // Generate a title
        Task {
            meetingItem.title.wrappedValue = try await meetingItem.wrappedValue.suggestedTitle() ?? meetingItem.title.wrappedValue
        }

        // Generate an image
        Task {
            meetingItem.isGeneratingImage.wrappedValue = true
            defer { meetingItem.isGeneratingImage.wrappedValue = false }

            let generatedImage = try await meetingItem.wrappedValue.suggestedImage()
            meetingItem.image.wrappedValue = generatedImage ?? meetingItem.image.wrappedValue
        }
    }

    func pauseRecording() {
        audioEngine.pause()
    }

    func resumeRecording() throws {
        try audioEngine.start()
    }

#if os(iOS)
    func setUpAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
#endif

    private func audioStream() async throws -> AsyncStream<AVAudioPCMBuffer> {
        try setupAudioEngine()
        audioEngine.inputNode.installTap(onBus: 0,
                                         bufferSize: 4096,
                                         format: audioEngine.inputNode.outputFormat(forBus: 0)) { [weak self] (buffer, time) in
            guard let self else { return }
            writeBufferToDisk(buffer: buffer)
            outputContinuation?.yield(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        return AsyncStream(AVAudioPCMBuffer.self, bufferingPolicy: .unbounded) {
            continuation in
            outputContinuation = continuation
        }
    }

    private func setupAudioEngine() throws {
        let inputSettings = audioEngine.inputNode.inputFormat(forBus: 0).settings
        file = try AVAudioFile(forWriting: url,
                                    settings: inputSettings)

        audioEngine.inputNode.removeTap(onBus: 0)
    }

    // Ask for permission to access the microphone.
    func isAuthorized() async -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            return true
        }

        return await AVCaptureDevice.requestAccess(for: .audio)
    }

    func writeBufferToDisk(buffer: AVAudioPCMBuffer) {
        do {
            try file?.write(from: buffer)
        } catch {
            print("file writing error: \(error)")
        }
    }
}
