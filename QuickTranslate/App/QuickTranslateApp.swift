import SwiftUI

@main
struct QuickTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appController = AppController.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appController)
        } label: {
            Label("Quick Translate", systemImage: "translate")
        }
        .menuBarExtraStyle(.window)

        Settings {
            EmptyView()
        }
    }
}
