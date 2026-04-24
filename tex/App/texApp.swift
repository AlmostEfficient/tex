import SwiftUI

@main
struct texApp: App {
    private static let settingsWindowID = "settings-window"

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

        Window("Settings", id: Self.settingsWindowID) {
            SettingsView()
                .environmentObject(appController)
        }
        .defaultSize(width: 460, height: 360)
        .windowResizability(.contentSize)
    }
}
