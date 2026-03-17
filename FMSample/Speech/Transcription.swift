/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Live transcription code.
*/

import Foundation
import Speech
import SwiftUI

@Observable
final class SpokenWordTranscriber {
    private var inputSequence: AsyncStream<AnalyzerInput>?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var recognizerTask: Task<(), Error>?

    static let magenta = Color(red: 0.54, green: 0.02, blue: 0.6).opacity(0.8) // #e81cff

    // The format of the audio.
    var analyzerFormat: AVAudioFormat?

    var converter = BufferConverter()
    var downloadProgress: Progress?

    var meetingItem: Binding<RecordingItem>

    @MainActor var volatileTranscript: AttributedString = ""
    @MainActor var finalizedTranscript: AttributedString = ""

    static let locale = Locale(components: .init(languageCode: .english, script: nil, languageRegion: .unitedStates))

    init(meetingItem: Binding<RecordingItem>) {
        self.meetingItem = meetingItem
    }

    func setUpTranscriber() async throws {
        transcriber = SpeechTranscriber(locale: Self.locale,
                                        transcriptionOptions: [],
                                        reportingOptions: [.volatileResults],
                                        attributeOptions: [.audioTimeRange])

        guard let transcriber else {
            throw TranscriptionError.failedToSetupRecognitionStream
        }

        analyzer = SpeechAnalyzer(modules: [transcriber])

        do {
            try await ensureModel(transcriber: transcriber, locale: Self.locale)
        } catch let error as TranscriptionError {
            print(error)
            return
        }

        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()

        guard let inputSequence else { return }

        recognizerTask = Task {
            do {
                for try await result in transcriber.results {
                    let text = result.text
                    await MainActor.run {
                        if result.isFinal {
                            finalizedTranscript += text
                            volatileTranscript = ""
                            updateItemWithNewText(withFinal: text)
                        } else {
                            volatileTranscript = text
                            volatileTranscript.foregroundColor = .purple.opacity(0.4)
                        }
                    }
                }
            } catch {
                print("speech recognition failed")
            }
        }

        try await analyzer?.start(inputSequence: inputSequence)
    }

    func updateItemWithNewText(withFinal str: AttributedString) {
        meetingItem.text.wrappedValue.append(str)
    }

    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
        guard let inputBuilder, let analyzerFormat else {
            throw TranscriptionError.invalidAudioDataType
        }

        let converted = try converter.convertBuffer(buffer, to: analyzerFormat)
        let input = AnalyzerInput(buffer: converted)

        inputBuilder.yield(input)
    }

    public func finishTranscribing() async throws {
        inputBuilder?.finish()
        try await analyzer?.finalizeAndFinishThroughEndOfInput()
        recognizerTask?.cancel()
        recognizerTask = nil
    }
}

public enum TranscriptionError: Error {
    case couldNotDownloadModel
    case failedToSetupRecognitionStream
    case invalidAudioDataType
    case localeNotSupported
    case noInternetForModelDownload
    case audioFilePathNotFound

    var descriptionString: String {
        switch self {

        case .couldNotDownloadModel:
            "Could not download the model."
        case .failedToSetupRecognitionStream:
            "Could not set up the speech recognition stream."
        case .invalidAudioDataType:
            "Unsupported audio format."
        case .localeNotSupported:
            "This locale is not yet supported by SpeechAnalyzer."
        case .noInternetForModelDownload:
            "The model could not be downloaded because the user is not connected to internet."
        case .audioFilePathNotFound:
            "Couldn't write audio to file."
        }
    }
}

public struct AudioData: @unchecked Sendable {
    var buffer: AVAudioPCMBuffer
    var time: AVAudioTime
}

extension SpokenWordTranscriber {
    public func ensureModel(transcriber: SpeechTranscriber, locale: Locale) async throws {
        guard await supported(locale: locale) else {
            throw TranscriptionError.localeNotSupported
        }

        if await installed(locale: locale) {
            return
        } else {
            try await downloadIfNeeded(for: transcriber)
        }
    }

    func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        return supported.map { $0.language }.contains(locale.language)
    }

    func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map { $0.language }.contains(locale.language)
    }

    func downloadIfNeeded(for module: SpeechTranscriber) async throws {
        if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
            downloadProgress = downloader.progress
            try await downloader.downloadAndInstall()
        }
    }

    func releaseLocales() async {
        let reserved = await AssetInventory.reservedLocales
        for locale in reserved {
            await AssetInventory.release(reservedLocale: locale)
        }
    }
}
