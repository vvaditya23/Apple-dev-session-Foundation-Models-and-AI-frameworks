/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model class for meeting items that represent project documents.
*/

import Foundation
import UniformTypeIdentifiers
import PDFKit

class DocumentItem: MeetingItem {
    override class var symbolName: String { "text.document" }
    override class var accessibilityLabel: String { "Document" }

    static let allowedTypes: [UTType] = [.text, .pdf, .rtf]

    init(fileURL: URL? = nil, isSecurityScoped: Bool = false) {
        super.init(
            title: fileURL?.lastPathComponent ?? "New Document",
            text: "",
            url: fileURL,
            isComplete: false
        )

        if let fileURL {
            Task {
                do {
                    guard !isSecurityScoped || fileURL.startAccessingSecurityScopedResource() else { return }
                    defer { if isSecurityScoped { fileURL.stopAccessingSecurityScopedResource() } }
                    try await loadFile()
                } catch {
                    print("Failed to read file at \(fileURL): \(error)")
                }
            }
        }
    }

    private func loadFile() async throws {
        guard let url else { return }

        let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
        let attributed: AttributedString
        if let contentType = resourceValues.contentType {
            if contentType.conforms(to: .plainText) {
                // Could be markdown or plain text
                let markdownExtensions = ["md", "markdown", "mdown", "mkd", "mkdn"]
                if markdownExtensions.contains(url.pathExtension.lowercased()) {
                    attributed = try AttributedString(contentsOf: url)
                } else {
                    let contents = try String(contentsOf: url, encoding: .utf8)
                    attributed = AttributedString(contents)
                }
            } else if contentType.conforms(to: .rtf) {
                let data = try Data(contentsOf: url)
                let nsAttributedString = try NSAttributedString(data: data, documentAttributes: nil)
                attributed = AttributedString(nsAttributedString)
            } else if contentType.conforms(to: .pdf) {
                guard let pdfDocument = PDFDocument(url: url) else {
                    throw DocumentError.cannotDetermineType(url: url)
                }
                attributed = (0 ..< pdfDocument.pageCount)
                    .compactMap { pdfDocument.page(at: $0)?.attributedString }
                    .compactMap { AttributedString($0) }
                    .joined(separator: "\n")
            } else {
                throw DocumentError.unsupportedType(contentType)
            }
        } else {
            throw DocumentError.cannotDetermineType(url: url)
        }
        text = attributed
        isComplete = true
    }

    enum DocumentError: Error {
        case unsupportedType(UTType)
        case cannotDetermineType(url: URL)
    }
}
