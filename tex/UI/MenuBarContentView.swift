import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var appController: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statusRow
            shortcutRow
            Divider()
            historySection
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 420)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("tex")
                .font(.system(size: 20, weight: .semibold))

            Text("Capture any screen region and translate detected text into English.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(appController.processingState.label)
                .font(.system(size: 13, weight: .medium))

            Spacer()

            if !appController.pendingQueue.isEmpty {
                Text("\(appController.pendingQueue.count) queued")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shortcutRow: some View {
        HStack {
            Text("Shortcut")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            ShortcutRecorderView()
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(.system(size: 13, weight: .semibold))

            if appController.historyStore.records.isEmpty {
                Text("No translations yet. Use the shortcut to capture an area of the screen.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(appController.historyStore.records) { record in
                            HistoryCard(
                                record: record,
                                sourceLanguage: appController.localizedLanguageName(for: record.sourceLanguage),
                                targetLanguage: appController.localizedLanguageName(for: record.targetLanguage),
                                onCopy: {
                                    appController.copy(record.translatedText)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: 360)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Clear History") {
                appController.clearHistory()
            }
            .buttonStyle(.link)
            .disabled(appController.historyStore.records.isEmpty)

            Spacer()

            Button("Quit") {
                appController.quit()
            }
            .keyboardShortcut("q")
        }
    }

    private var statusColor: Color {
        switch appController.processingState {
        case .idle:
            return Color(red: 0.34, green: 0.75, blue: 0.50)
        case .capturing:
            return Color(red: 0.25, green: 0.62, blue: 0.96)
        case .recognizing:
            return Color(red: 0.98, green: 0.72, blue: 0.29)
        case .translating:
            return Color(red: 0.90, green: 0.51, blue: 0.24)
        }
    }
}

private struct HistoryCard: View {
    let record: TranslationRecord
    let sourceLanguage: String
    let targetLanguage: String
    let onCopy: () -> Void

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.translatedText)
                        .font(.system(size: 14, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(sourceLanguage) → \(targetLanguage)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Copy", action: onCopy)
                    .buttonStyle(.borderless)
                    .font(.system(size: 11, weight: .semibold))
            }

            Text(record.sourceText)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Text(Self.relativeFormatter.localizedString(for: record.capturedAt, relativeTo: .now))
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
