import AppKit
import SwiftUI

@MainActor
final class TranslationPopupController {
    fileprivate struct PopupPayload {
        let title: String
        let markdown: String
        let footnote: String
        let accentColor: Color
    }

    private var panel: NSPanel?

    func present(record: TranslationRecord) {
        present(
            payload: PopupPayload(
                title: "Formatted Translation",
                markdown: record.markdown,
                footnote: record.modelName,
                accentColor: Color(red: 0.34, green: 0.75, blue: 0.50)
            )
        )
    }

    func presentError(_ message: String) {
        present(
            payload: PopupPayload(
                title: "tex",
                markdown: message,
                footnote: "Gemini request failed",
                accentColor: Color(red: 0.98, green: 0.47, blue: 0.39)
            )
        )
    }

    func dismiss() {
        panel?.orderOut(nil)
    }

    private func present(payload: PopupPayload) {
        let panel = panel ?? makePanel()
        panel.contentView = NSHostingView(
            rootView: TranslationPopupCard(payload: payload) { [weak self] in
                self?.dismiss()
            }
        )
        position(panel)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 340),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.level = .floating
        return panel
    }

    private func position(_ panel: NSPanel) {
        let screen = NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let panelSize = panel.frame.size
        let origin = CGPoint(
            x: visibleFrame.maxX - panelSize.width - 20,
            y: visibleFrame.minY + 20
        )

        panel.setFrameOrigin(origin)
    }
}

private struct TranslationPopupCard: View {
    let payload: TranslationPopupController.PopupPayload
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(payload.accentColor)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(payload.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(payload.footnote)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                Button(action: copyMarkdown) {
                    Text("Copy")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.78))

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.72))
            }

            ScrollView {
                Text(markdownBody)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 4)
            }
        }
        .padding(16)
        .frame(width: 460, height: 340, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var markdownBody: AttributedString {
        do {
            return try AttributedString(
                markdown: payload.markdown,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
        } catch {
            return AttributedString(payload.markdown)
        }
    }

    private func copyMarkdown() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(payload.markdown, forType: .string)
    }
}
