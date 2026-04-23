import Foundation

struct TranslationRecord: Codable, Hashable, Identifiable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let capturedAt: Date
    let sourceLanguage: String?
    let targetLanguage: String

    init(
        id: UUID = UUID(),
        sourceText: String,
        translatedText: String,
        capturedAt: Date = .now,
        sourceLanguage: String?,
        targetLanguage: String
    ) {
        self.id = id
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.capturedAt = capturedAt
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
    }
}
