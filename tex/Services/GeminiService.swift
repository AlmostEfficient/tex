import Foundation

enum GeminiServiceError: LocalizedError {
    case invalidResponse
    case noTextReturned
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Gemini returned an invalid response."
        case .noTextReturned:
            return "Gemini returned an empty translation."
        case .apiError(let message):
            return message
        }
    }
}

struct GeminiService {
    let modelName = "gemini-2.5-flash"

    func translateImage(data: Data, mimeType: String, apiKey: String) async throws -> String {
        let requestBody = GenerateContentRequest(
            contents: [
                Content(
                    parts: [
                        Part(
                            inlineData: InlineData(
                                mimeType: mimeType,
                                data: data.base64EncodedString()
                            )
                        ),
                        Part(
                            text: """
                            Translate all Chinese text in this image into English.
                            Return only the translated content as Markdown for display in a popup.
                            Preserve reading order, paragraph breaks, list structure, and approximate spacing as closely as possible.
                            Do not add explanations, notes, or code fences.
                            If there is no Chinese text, return exactly: No Chinese text found.
                            """
                        )
                    ]
                )
            ],
            generationConfig: GenerationConfig(temperature: 0.2)
        )

        var request = URLRequest(
            url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent")!
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIErrorEnvelope.self, from: responseData) {
                throw GeminiServiceError.apiError(apiError.error.message)
            }

            throw GeminiServiceError.apiError("Gemini request failed with status \(httpResponse.statusCode).")
        }

        let payload = try JSONDecoder().decode(GenerateContentResponse.self, from: responseData)
        let text = payload.candidates
            .flatMap(\.content.parts)
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw GeminiServiceError.noTextReturned
        }

        return stripCodeFences(from: text)
    }

    private func stripCodeFences(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```"), trimmed.hasSuffix("```") else {
            return trimmed
        }

        let lines = trimmed.components(separatedBy: .newlines)
        guard lines.count >= 3 else {
            return trimmed
        }

        return lines.dropFirst().dropLast().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct GenerateContentRequest: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig
}

private struct Content: Encodable {
    let parts: [Part]
}

private struct Part: Encodable {
    let text: String?
    let inlineData: InlineData?

    init(text: String) {
        self.text = text
        self.inlineData = nil
    }

    init(inlineData: InlineData) {
        self.text = nil
        self.inlineData = inlineData
    }

    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
    }
}

private struct InlineData: Encodable {
    let mimeType: String
    let data: String

    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
}

private struct GenerationConfig: Encodable {
    let temperature: Double
}

private struct GenerateContentResponse: Decodable {
    let candidates: [Candidate]
}

private struct Candidate: Decodable {
    let content: CandidateContent
}

private struct CandidateContent: Decodable {
    let parts: [CandidatePart]
}

private struct CandidatePart: Decodable {
    let text: String?
}

private struct APIErrorEnvelope: Decodable {
    let error: APIError
}

private struct APIError: Decodable {
    let message: String
}
