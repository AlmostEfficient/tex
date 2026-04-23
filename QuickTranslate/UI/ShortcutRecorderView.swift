import SwiftUI
import Carbon

struct ShortcutRecorderView: View {
    @State private var isRecording = false
    @State private var tempKeyCode: UInt32?
    @State private var tempModifiers: UInt32?

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

            if !isRecording && !isDefaultShortcut {
                Button(action: resetToDefault) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Reset to default")
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if isRecording {
                    handleKeyEvent(event)
                    return nil
                }
                return event
            }
        }
    }

    private var isDefaultShortcut: Bool {
        ShortcutPreference.shared.keyCode == ShortcutPreference.shared.defaultKeyCode &&
        ShortcutPreference.shared.modifiers == ShortcutPreference.shared.defaultModifiers
    }

    private func startRecording() {
        tempKeyCode = nil
        tempModifiers = nil
        isRecording = true
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let keyCode = UInt32(event.keyCode)
        let modifiers = UInt32(event.modifierFlags.intersection([.control, .option, .command, .shift]).rawValue)

        guard modifiers != 0 else {
            NSSound.beep()
            return
        }

        tempKeyCode = keyCode
        tempModifiers = modifiers

        ShortcutPreference.shared.keyCode = keyCode
        ShortcutPreference.shared.modifiers = modifiers

        isRecording = false

        NotificationCenter.default.post(name: .shortcutDidChange, object: nil)
    }

    private func resetToDefault() {
        ShortcutPreference.shared.resetToDefault()
        NotificationCenter.default.post(name: .shortcutDidChange, object: nil)
    }
}

extension Notification.Name {
    static let shortcutDidChange = Notification.Name("shortcutDidChange")
}
