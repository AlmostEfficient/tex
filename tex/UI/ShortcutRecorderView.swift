import SwiftUI
import Carbon

struct ShortcutRecorderView: View {
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            if isRecording {
                Text("Press new shortcut...")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            } else {
                Text(ShortcutPreference.shared.description)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.secondary.opacity(0.12))
                    )
            }

            Button(action: startRecording) {
                Image(systemName: isRecording ? "stop.circle.fill" : "pencil.circle")
                    .font(.system(size: 14))
            }
            .buttonStyle(.borderless)
            .help(isRecording ? "Cancel" : "Change shortcut")

            if !isRecording && !ShortcutPreference.shared.isDefaultShortcut {
                Button(action: resetToDefault) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Reset to default")
            }
        }
        .onAppear(perform: installEventMonitor)
        .onDisappear(perform: removeEventMonitor)
    }

    private func startRecording() {
        isRecording.toggle()
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let keyCode = UInt32(event.keyCode)
        let modifiers = carbonModifiers(from: event.modifierFlags)

        guard modifiers != 0 else {
            NSSound.beep()
            return
        }

        ShortcutPreference.shared.keyCode = keyCode
        ShortcutPreference.shared.modifiers = modifiers

        isRecording = false

        NotificationCenter.default.post(name: .shortcutDidChange, object: nil)
    }

    private func resetToDefault() {
        ShortcutPreference.shared.resetToDefault()
        NotificationCenter.default.post(name: .shortcutDidChange, object: nil)
    }

    private func installEventMonitor() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            guard isRecording else {
                return event
            }

            handleKeyEvent(event)
            return nil
        }
    }

    private func removeEventMonitor() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }

        isRecording = false
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0

        if flags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if flags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        if flags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }

        return modifiers
    }
}

extension Notification.Name {
    static let shortcutDidChange = Notification.Name("shortcutDidChange")
}
