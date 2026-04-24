import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var appController: AppController
    @Environment(\.openWindow) private var openWindow

    private let settingsWindowID = "settings-window"

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statusRow
            apiKeyRow
            shortcutRow
            Divider()
            captureRow
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
            HStack(spacing: 8) {
                Text("tex")
                    .font(.system(size: 20, weight: .semibold))

                Text(appVersion)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                    )
            }

            Text("Capture a screen region and send it directly to Gemini 1.5 Flash for formatted translation.")
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
        }
    }

    private var apiKeyRow: some View {
        HStack {
            Text("Gemini API")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text(appController.hasAPIKey ? "Configured" : "Missing")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(appController.hasAPIKey ? .green : .red)
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

    private var captureRow: some View {
        Button {
            Task {
                await appController.captureAndTranslate()
            }
        } label: {
            HStack {
                Image(systemName: "sparkles.rectangle.stack")
                Text("Translate Selected Area")
                Spacer()
                Text(appController.currentModelName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(appController.captureInFlight)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Results")
                .font(.system(size: 13, weight: .semibold))

            if appController.historyStore.records.isEmpty {
                Text("No translations yet. Use the shortcut or the button above to capture a region.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(appController.historyStore.records) { record in
                            HistoryCard(
                                record: record,
                                onCopy: {
                                    appController.copy(record.markdown)
                                },
                                onShow: {
                                    appController.popupController.present(record: record)
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

            Button("Settings…") {
                openWindow(id: settingsWindowID)
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.link)
            .keyboardShortcut(",", modifiers: .command)

            Divider()
                .frame(height: 16)

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
        case .sendingToGemini:
            return Color(red: 0.90, green: 0.51, blue: 0.24)
        }
    }
}

private struct HistoryCard: View {
    let record: TranslationRecord
    let onCopy: () -> Void
    let onShow: () -> Void

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.previewText)
                        .font(.system(size: 14, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(record.modelName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button("Show", action: onShow)
                        .buttonStyle(.borderless)
                        .font(.system(size: 11, weight: .semibold))

                    Button("Copy", action: onCopy)
                        .buttonStyle(.borderless)
                        .font(.system(size: 11, weight: .semibold))
                }
            }

            Text(record.previewText)
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

private extension TranslationRecord {
    var previewText: String {
        markdown
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
