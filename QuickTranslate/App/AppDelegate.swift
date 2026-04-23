import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var translationHostWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppController.shared.start()
        installTranslationHostWindow()
    }

    private func installTranslationHostWindow() {
        let rootView = TranslationWorkerView()
            .environmentObject(AppController.shared)

        let hostingView = NSHostingView(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.alphaValue = 0.001
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isOpaque = false
        window.level = .normal
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.contentView = hostingView
        window.orderFrontRegardless()
        window.orderBack(nil)

        translationHostWindow = window
    }
}
