import AppKit
import SwiftUI

@MainActor
final class TranslationPopupController {
    fileprivate struct PopupPayload {
        let title: String
        let body: String
        let footnote: String?
        let accentColor: Color
    }

    private var panel: NSPanel?
    private var autoDismissTask: Task<Void, Never>?

    func present(record: TranslationRecord) {
        present(
            payload: PopupPayload(
                title: "Translated to English",
                body: record.translatedText,
                footnote: excerpt(for: record.sourceText),
                accentColor: Color(red: 0.34, green: 0.75, blue: 0.50)
            )
        )
    }

    func presentError(_ message: String) {
        present(
            payload: PopupPayload(
                title: "tex",
                body: message,
                footnote: nil,
                accentColor: Color(red: 0.98, green: 0.47, blue: 0.39)
            )
        )
    }

    func dismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
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

        autoDismissTask?.cancel()
        autoDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.dismiss()
            }
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 184),
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
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let panelSize = panel.frame.size
        let origin = CGPoint(
            x: visibleFrame.maxX - panelSize.width - 20,
            y: visibleFrame.minY + 20
        )

        panel.setFrameOrigin(origin)
    }

    private func excerpt(for text: String) -> String {
        let singleLine = text
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if singleLine.count <= 140 {
            return singleLine
        }

        return String(singleLine.prefix(140)) + "..."
    }
}

private struct TranslationPopupCard: View {
    let payload: TranslationPopupController.PopupPayload
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(payload.accentColor)
                    .frame(width: 10, height: 10)

                Text(payload.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Text(payload.body)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            if let footnote = payload.footnote, !footnote.isEmpty {
                Text(footnote)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(width: 360, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .onTapGesture(perform: onDismiss)
    }
}
