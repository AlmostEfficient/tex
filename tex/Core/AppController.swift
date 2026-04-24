import AppKit
import Foundation
import Translation

@MainActor
final class AppController: ObservableObject {
    static let shared = AppController()

    enum ProcessingState: Equatable {
        case idle
        case capturing
        case recognizing
        case translating

        var label: String {
            switch self {
            case .idle:
                return "Ready"
            case .capturing:
                return "Capturing selection"
            case .recognizing:
                return "Recognizing text"
            case .translating:
                return "Translating to English"
            }
        }
    }

    struct PendingTranslation: Identifiable, Equatable {
        let id: UUID
        let sourceText: String
        let createdAt: Date
    }

    @Published private(set) var processingState: ProcessingState = .idle
    @Published private(set) var captureInFlight = false
    @Published private(set) var pendingQueue: [PendingTranslation] = []
    @Published var translationConfiguration: TranslationSession.Configuration?

    let historyStore = TranslationHistoryStore()
    let popupController = TranslationPopupController()

    private let captureService = ScreenCaptureService()
    private let ocrService = OCRService()

    private var activeTranslation: PendingTranslation?
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
    }

    var hotKeyLabel: String {
        HotKeyMonitor.shortcutDescription
    }

    private func reregisterHotKey() {
        HotKeyMonitor.shared.reregister {
            Task { @MainActor in
                await self.captureAndTranslateFromHotKey()
            }
        }
    }

    var currentPendingTranslation: PendingTranslation? {
        activeTranslation
    }

    func start() {
        guard !hotKeyRegistered else { return }

        hotKeyRegistered = true
        HotKeyMonitor.shared.register {
            Task { @MainActor in
                await self.captureAndTranslateFromHotKey()
            }
        }
    }

    func captureAndTranslateFromHotKey() async {
        guard !captureInFlight else { return }

        captureInFlight = true
        processingState = .capturing

        do {
            guard let imageURL = try await captureService.captureSelection() else {
                processingState = activeTranslation == nil && pendingQueue.isEmpty ? .idle : .translating
                captureInFlight = false
                return
            }

            processingState = .recognizing
            let recognizedText = try await ocrService.recognizeText(in: imageURL)
            try? FileManager.default.removeItem(at: imageURL)

            pendingQueue.append(
                PendingTranslation(
                    id: UUID(),
                    sourceText: recognizedText,
                    createdAt: .now
                )
            )
            captureInFlight = false
            pumpTranslationQueue()
        } catch let error as OCRServiceError {
            processingState = activeTranslation == nil && pendingQueue.isEmpty ? .idle : .translating
            captureInFlight = false
            popupController.presentError(error.localizedDescription)
        } catch {
            processingState = activeTranslation == nil && pendingQueue.isEmpty ? .idle : .translating
            captureInFlight = false
            popupController.presentError(error.localizedDescription)
        }
    }

    func completeTranslation(
        _ pending: PendingTranslation,
        translatedText: String,
        sourceLanguage: String,
        targetLanguage: String
    ) {
        let record = TranslationRecord(
            sourceText: pending.sourceText,
            translatedText: translatedText,
            capturedAt: pending.createdAt,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )

        historyStore.add(record)
        popupController.present(record: record)
        finishTranslation(for: pending)
    }

    func failTranslation(_ pending: PendingTranslation, message: String) {
        popupController.presentError(message)
        finishTranslation(for: pending)
    }

    func clearHistory() {
        historyStore.clear()
    }

    func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func localizedLanguageName(for identifier: String?) -> String {
        guard let identifier, !identifier.isEmpty else {
            return "Auto"
        }

        let locale = Locale.current
        return locale.localizedString(forIdentifier: identifier) ?? identifier
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func pumpTranslationQueue() {
        guard activeTranslation == nil else { return }
        guard !pendingQueue.isEmpty else {
            processingState = captureInFlight ? .capturing : .idle
            return
        }

        activeTranslation = pendingQueue.removeFirst()
        processingState = .translating
        translationConfiguration = TranslationSession.Configuration(
            source: nil,
            target: Locale.Language(identifier: "en")
        )
    }

    private func finishTranslation(for pending: PendingTranslation) {
        if activeTranslation?.id == pending.id {
            activeTranslation = nil
            translationConfiguration = nil
            processingState = captureInFlight ? .capturing : .idle
        }

        pumpTranslationQueue()
    }
}
