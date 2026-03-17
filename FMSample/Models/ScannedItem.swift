/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model class for meeting items that represent document / whiteboard scans.
*/

import Foundation
import VisionKit
import Vision

class ScannedItem: MeetingItem {
    override class var symbolName: String { "text.viewfinder" }
    override class var accessibilityLabel: String { "Scanned Document" }

    private var pages: [CGImage] = []

#if os(iOS)
    init(scan: VNDocumentCameraScan) {
        super.init(
            title: scan.title.isEmpty ? "New Scanned Item" : scan.title,
            text: "",
            url: nil,
            isComplete: false
        )

        pages = (0..<scan.pageCount).compactMap { scan.imageOfPage(at: $0).cgImage }
        if !pages.isEmpty {
            Task {
                do {
                    text = try await AttributedString(recognize())
                    isComplete = true
                } catch {
                    print("Failed to recognize text: \(error)")
                }
            }
        }
    }
#endif

    // I've written this. If not working calll `recognizeText` (Pre-written method)
    private func recognize() async throws -> String {
        return try await withThrowingTaskGroup(of: (Int, String).self) { group in
            var results: [Int : String] = [:]
            
            for (pageindex, image) in pages.enumerated() {
                group.addTask {
                    let request  = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    
                    let handler = VNImageRequestHandler(cgImage: image, options: [:])
                    try handler.perform([request])
                    
                    guard let observations = request.results else {
                        return (pageindex, "")
                    }
                    
                    let pageText = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }.joined(separator: "\n")
                    
                    return (pageindex, pageText)
                }
            }
            
            for try await (index, text) in group {
                results[index] = text
            }
            // Return in page order
            return (0 ..< pages.count).compactMap { results[$0] }.joined(separator: "\n\n")
        }
    }
    
    private func recognizeText() async throws -> String {
        return try await withThrowingTaskGroup(of: (Int, String).self) { group in
            var results: [Int: String] = [:]

            for (pageIndex, image) in pages.enumerated() {
                group.addTask {
                    let request = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true

                    // Optionally specify languages for better accuracy
                    request.recognitionLanguages = ["en-US"]
                    // request.recognitionLanguages = ["en-US", "es-ES"]
                    // request.customWords = ["Foo", "Bar"]
                    // request.minimumTextHeight = 0.01

                    let handler = VNImageRequestHandler(cgImage: image, options: [:])
                    try handler.perform([request])

                    guard let observations = request.results else {
                        return (pageIndex, "")
                    }

                    let pageText = observations.compactMap { observation in
                        observation.topCandidates(1).first?.string
                    }.joined(separator: "\n")

                    return (pageIndex, pageText)
                }
            }

            for try await (index, text) in group {
                results[index] = text
            }

            // Return in page order
            return (0 ..< pages.count).compactMap { results[$0] }.joined(separator: "\n\n")
        }
    }
}
