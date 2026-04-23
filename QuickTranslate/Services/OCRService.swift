import Foundation
import Vision

enum OCRServiceError: LocalizedError {
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .noTextFound:
            return "No text was detected in the captured area."
        }
    }
}

struct OCRService {
    func recognizeText(in imageURL: URL) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(url: imageURL)
            try handler.perform([request])

            let text = (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !text.isEmpty else {
                throw OCRServiceError.noTextFound
            }

            return text
        }.value
    }
}
