import Carbon
import Foundation

@MainActor
final class HotKeyMonitor {
    static let shared = HotKeyMonitor()
    static var shortcutDescription: String { ShortcutPreference.shared.description }

    private static let hotKeyIDValue: UInt32 = 1
    private static let signature: OSType = 0x5154524E
    nonisolated(unsafe) fileprivate static var handler: (@MainActor () -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private init() {}

    func register(handler: @escaping @MainActor () -> Void) {
        Self.handler = handler
        unregister()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            quickTranslateHotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: Self.hotKeyIDValue)
        RegisterEventHotKey(
            ShortcutPreference.shared.keyCode,
            ShortcutPreference.shared.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    func reregister(handler: @escaping @MainActor () -> Void) {
        register(handler: handler)
    }
}

private func quickTranslateHotKeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    var hotKeyID = EventHotKeyID()
    GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    guard hotKeyID.id == 1 else {
        return noErr
    }

    Task { @MainActor in
        HotKeyMonitor.handler?()
    }

    return noErr
}
