import AppKit
import SwiftUI

struct PermissionItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let isGranted: Bool
    let openSettings: () -> Void
}

struct SettingsView: View {
    @EnvironmentObject private var appController: AppController
    @State private var permissions: [PermissionItem] = []
    @State private var apiKey = ""
    @State private var saveMessage: String?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gemini Model")
                        .font(.headline)

                    Text("This build sends your selected screenshot directly to Gemini `\(appController.currentModelName)` and expects Markdown back.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("The API key is stored locally in the app preferences for this Mac so the app does not trigger Keychain access prompts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SecureField("Paste Gemini API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Save Key") {
                            saveMessage = appController.saveGeminiAPIKey(apiKey) ?? "API key saved locally."
                            loadKey()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Clear Key") {
                            apiKey = ""
                            saveMessage = appController.saveGeminiAPIKey("") ?? "API key removed."
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    if let saveMessage {
                        Text(saveMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Gemini")
            }

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current capture mode: Direct region capture")
                        .font(.headline)

                    Text("This app currently uses macOS direct screen capture for arbitrary region selection. On recent macOS versions, that can trigger the “bypass the system private window picker” warning.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Avoiding that warning requires switching the app to Apple’s system content-sharing picker, which changes capture behavior from freeform region selection to picking a window, app, or display.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Capture")
            }

            Section {
                ForEach(permissions) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(item.isGranted ? .green : .red)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if !item.isGranted {
                            Button("Open System Settings") {
                                item.openSettings()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Permissions")
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .task {
            loadPermissions()
            loadKey()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loadPermissions()
            appController.refreshConfigurationState()
        }
    }

    private func loadPermissions() {
        var items: [PermissionItem] = []

        let screenCaptureGranted = CGPreflightScreenCaptureAccess()
        let screenCaptureDescription = "Required for capturing screen regions for translation"
        items.append(PermissionItem(
            title: "Screen Recording",
            description: screenCaptureDescription,
            isGranted: screenCaptureGranted,
            openSettings: {
                openPrivacySettings(anchor: "Privacy_ScreenCapture")
            }
        ))

        permissions = items
    }

    private func loadKey() {
        apiKey = appController.geminiAPIKey() ?? ""
    }

    private func openPrivacySettings(anchor: String) {
        let urlString: String
        if anchor.isEmpty {
            urlString = "x-apple.systempreferences:com.apple.preference.security"
        } else {
            urlString = "x-apple.systempreferences:com.apple.preference.security?\(anchor)"
        }

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
