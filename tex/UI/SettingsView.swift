import SwiftUI
import ScreenCaptureKit

struct PermissionItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let isGranted: Bool
    let openSettings: () -> Void
}

struct SettingsView: View {
    @State private var permissions: [PermissionItem] = []

    var body: some View {
        Form {
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
        .frame(width: 400, height: 200)
        .task {
            loadPermissions()
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

    private func openPrivacySettings(anchor: String) {
        if let url = URL(string: "x-apple.systempreferences:\(anchor.isEmpty ? "" : "?anchor=\(anchor)")") {
            NSWorkspace.shared.open(url)
        }
    }
}
