import Foundation

@MainActor
final class TranslationHistoryStore: ObservableObject {
    @Published private(set) var records: [TranslationRecord] = []

    private let defaultsKey = "quick-translate.history"
    private let maxRecords = 100
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        load()
    }

    func add(_ record: TranslationRecord) {
        records.insert(record, at: 0)

        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
        }

        save()
    }

    func clear() {
        records.removeAll()
        save()
    }

    private func load() {
        decoder.dateDecodingStrategy = .iso8601

        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            return
        }

        do {
            records = try decoder.decode([TranslationRecord].self, from: data)
        } catch {
            records = []
        }
    }

    private func save() {
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(records) else {
            return
        }

        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
