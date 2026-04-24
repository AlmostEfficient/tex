import AppKit
import Foundation

@MainActor
final class AppController: ObservableObject {
    static let shared = AppController()

    enum ProcessingState: Equatable {
        case idle
        case capturing
        case sendingToGemini

        var label: String {
            switch self {
            case .idle:
                return "Ready"
            case .capturing:
                return "Capturing selection"
            case .sendingToGemini:
                return "Formatting translation"
            }
        }

        var accentColor: NSColor {
            switch self {
            case .idle:
                return NSColor(calibratedRed: 0.34, green: 0.75, blue: 0.50, alpha: 1)
            case .capturing:
                return NSColor(calibratedRed: 0.25, green: 0.62, blue: 0.96, alpha: 1)
            case .sendingToGemini:
                return NSColor(calibratedRed: 0.98, green: 0.72, blue: 0.29, alpha: 1)
            }
        }
    }

    @Published private(set) var processingState: ProcessingState = .idle
    @Published private(set) var captureInFlight = false
    @Published private(set) var hasAPIKey = false

    let historyStore = TranslationHistoryStore()
    let popupController = TranslationPopupController()

    private let captureService = ScreenCaptureService()
    private let geminiService = GeminiService()
    private let secretsStore = SecretsStore()
    private var hotKeyRegistered = false

    private init() {
        NotificationCenter.default.addObserver(
            forName: .shortcutDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reregisterHotKey()
            }
        }

        refreshConfigurationState()
    }

    var hotKeyLabel: String {
        HotKeyMonitor.shortcutDescription
    }

    var currentModelName: String {
        geminiService.modelName
    }

    private func reregisterHotKey() {
        HotKeyMonitor.shared.reregister {
            Task { @MainActor in
                await self.captureAndTranslate()
            }
        }
    }

    var latestRecord: TranslationRecord? {
        historyStore.records.first
    }

    func start() {
        guard !hotKeyRegistered else { return }

        hotKeyRegistered = true
        HotKeyMonitor.shared.register {
            Task { @MainActor in
                await self.captureAndTranslate()
            }
        }
    }

    func captureAndTranslate() async {
        guard !captureInFlight else { return }

        guard let apiKey = geminiAPIKey(), !apiKey.isEmpty else {
            popupController.presentError("Add your Gemini API key in Settings before translating.")
            refreshConfigurationState()
            return
        }

        guard ensureScreenCaptureAccess() else {
            popupController.presentError("Screen Recording permission is required before capturing.")
            return
        }

        captureInFlight = true
        processingState = .capturing

        do {
            guard let capturedImage = try await captureService.captureSelection() else {
                processingState = .idle
                captureInFlight = false
                return
            }

            processingState = .sendingToGemini
            popupController.presentLoading()
            let markdown = try await geminiService.translateImage(
                data: capturedImage.data,
                mimeType: capturedImage.mimeType,
                apiKey: apiKey
            )

            let record = TranslationRecord(
                markdown: markdown,
                capturedAt: .now,
                modelName: geminiService.modelName
            )
            historyStore.add(record)
            popupController.present(record: record)
        } catch {
            popupController.presentError(error.localizedDescription)
        }

        processingState = .idle
        captureInFlight = false
    }

    func clearHistory() {
        historyStore.clear()
    }

    func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func refreshConfigurationState() {
        hasAPIKey = !(geminiAPIKey()?.isEmpty ?? true)
    }

    func geminiAPIKey() -> String? {
        try? secretsStore.loadGeminiAPIKey()
    }

    func saveGeminiAPIKey(_ apiKey: String) -> String? {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if trimmed.isEmpty {
                try secretsStore.deleteGeminiAPIKey()
            } else {
                try secretsStore.saveGeminiAPIKey(trimmed)
            }
            refreshConfigurationState()
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func ensureScreenCaptureAccess() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }

        return CGRequestScreenCaptureAccess()
    }
}
