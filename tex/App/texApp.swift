import SwiftUI

@main
struct texApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appController = AppController.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appController)
        } label: {
            Label("tex", systemImage: "translate")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
