import Foundation

struct TranslationRecord: Codable, Hashable, Identifiable {
    let id: UUID
    let markdown: String
    let capturedAt: Date
    let modelName: String

    init(
        id: UUID = UUID(),
        markdown: String,
        capturedAt: Date = .now,
        modelName: String
    ) {
        self.id = id
        self.markdown = markdown
        self.capturedAt = capturedAt
        self.modelName = modelName
    }
}
