import SwiftUI
import Translation

struct TranslationWorkerView: View {
    @EnvironmentObject private var appController: AppController

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .translationTask(appController.translationConfiguration) { session in
                guard let pending = appController.currentPendingTranslation else {
                    return
                }

                do {
                    let response = try await Task { @MainActor in
                        try await session.translate(pending.sourceText)
                    }.value
                    appController.completeTranslation(
                        pending,
                        translatedText: response.targetText,
                        sourceLanguage: response.sourceLanguage.minimalIdentifier,
                        targetLanguage: response.targetLanguage.minimalIdentifier
                    )
                } catch {
                    appController.failTranslation(
                        pending,
                        message: "Translation failed: \(error.localizedDescription)"
                    )
                }
            }
    }
}
