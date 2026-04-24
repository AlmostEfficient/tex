import AppKit
import SwiftUI

@MainActor
final class TranslationPopupController {
    private static let autoDismissDelay: Duration = .seconds(15)

    fileprivate struct PopupPayload {
        enum Content {
            case loading(message: String)
            case markdown(String)
        }

        let title: String
        let content: Content
        let footnote: String
        let accentColor: Color
    }

    private var panel: NSPanel?
    private var autoDismissTask: Task<Void, Never>?

    func present(record: TranslationRecord) {
        present(
            payload: PopupPayload(
                title: "Formatted Translation",
                content: .markdown(record.markdown),
                footnote: record.modelName,
                accentColor: Color(red: 0.34, green: 0.75, blue: 0.50)
            )
        )
        scheduleAutoDismiss()
    }

    func presentLoading() {
        present(
            payload: PopupPayload(
                title: "Formatting Translation",
                content: .loading(message: "Sending your screenshot to Gemini and preparing the result."),
                footnote: "Gemini request in progress",
                accentColor: Color(red: 0.98, green: 0.72, blue: 0.29)
            )
        )
        cancelAutoDismiss()
    }

    func presentError(_ message: String) {
        present(
            payload: PopupPayload(
                title: "tex",
                content: .markdown(message),
                footnote: "Gemini request failed",
                accentColor: Color(red: 0.98, green: 0.47, blue: 0.39)
            )
        )
        cancelAutoDismiss()
    }

    func dismiss() {
        cancelAutoDismiss()
        panel?.orderOut(nil)
    }

    private func present(payload: PopupPayload) {
        let panel = panel ?? makePanel()
        (panel as? PopupPanel)?.onClose = { [weak self] in
            self?.dismiss()
        }
        panel.contentView = NSHostingView(
            rootView: TranslationPopupCard(payload: payload) { [weak self] in
                self?.dismiss()
            }
        )
        position(panel)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    private func makePanel() -> NSPanel {
        let panel = PopupPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 340),
            styleMask: [.borderless],
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

    private func scheduleAutoDismiss() {
        cancelAutoDismiss()
        autoDismissTask = Task { [weak self] in
            try? await Task.sleep(for: Self.autoDismissDelay)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.dismiss()
            }
        }
    }

    private func cancelAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }
}

private final class PopupPanel: NSPanel {
    var onClose: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onClose?()
    }

    override func performClose(_ sender: Any?) {
        onClose?()
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == [.command],
           event.charactersIgnoringModifiers?.lowercased() == "w" {
            onClose?()
            return
        }

        super.keyDown(with: event)
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

                if case .markdown = payload.content {
                    Button(action: copyMarkdown) {
                        Text("Copy")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.78))
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.72))
            }

            contentView
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

    @ViewBuilder
    private var contentView: some View {
        switch payload.content {
        case .loading(let message):
            VStack(alignment: .leading, spacing: 16) {
                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(.white)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Working on it")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )

                Spacer(minLength: 0)
            }
        case .markdown(let markdown):
            ScrollView {
                SelectableMarkdownTextView(markdown: markdownBody(markdown))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 4)
            }
        }
    }

    private func markdownBody(_ markdown: String) -> AttributedString {
        do {
            return try AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
        } catch {
            return AttributedString(markdown)
        }
    }

    private func copyMarkdown() {
        guard case .markdown(let markdown) = payload.content else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(markdown, forType: .string)
    }
}

private struct SelectableMarkdownTextView: NSViewRepresentable {
    let markdown: AttributedString

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = NSTextView()
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textColor = .white
        textView.font = .systemFont(ofSize: 15)

        scrollView.documentView = textView
        update(textView: textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        update(textView: textView)
    }

    private func update(textView: NSTextView) {
        let mutable = NSMutableAttributedString(markdown)
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.addAttributes(
            [
                .foregroundColor: NSColor.white,
                .font: NSFont.systemFont(ofSize: 15)
            ],
            range: fullRange
        )
        textView.textStorage?.setAttributedString(mutable)
    }
}
