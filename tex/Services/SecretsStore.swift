import Foundation

struct SecretsStore {
    private let geminiAPIKey = "gemini.apiKey"
    private let defaults = UserDefaults.standard

    func loadGeminiAPIKey() throws -> String? {
        defaults.string(forKey: geminiAPIKey)
    }

    func saveGeminiAPIKey(_ value: String) throws {
        defaults.set(value, forKey: geminiAPIKey)
    }

    func deleteGeminiAPIKey() throws {
        defaults.removeObject(forKey: geminiAPIKey)
    }
}
