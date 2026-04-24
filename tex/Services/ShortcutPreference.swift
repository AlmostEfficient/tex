import Foundation
import Carbon

@MainActor
final class ShortcutPreference {
    static let shared = ShortcutPreference()

    private let keyCodeKey = "shortcut.keyCode"
    private let modifiersKey = "shortcut.modifiers"

    let defaultKeyCode: UInt32 = UInt32(kVK_ANSI_T)
    let defaultModifiers: UInt32 = UInt32(controlKey | optionKey | cmdKey)

    private init() {}

    var keyCode: UInt32 {
        get {
            guard let saved = UserDefaults.standard.object(forKey: keyCodeKey) as? NSNumber else {
                return defaultKeyCode
            }

            return saved.uint32Value
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: keyCodeKey)
        }
    }

    var modifiers: UInt32 {
        get {
            guard let saved = UserDefaults.standard.object(forKey: modifiersKey) as? NSNumber else {
                return defaultModifiers
            }

            return saved.uint32Value
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: modifiersKey)
        }
    }

    var isDefaultShortcut: Bool {
        keyCode == defaultKeyCode && modifiers == defaultModifiers
    }

    var description: String {
        let modifierDescriptions: [String] = [
            (modifiers & UInt32(controlKey) != 0) ? "Control" : nil,
            (modifiers & UInt32(optionKey) != 0) ? "Option" : nil,
            (modifiers & UInt32(cmdKey) != 0) ? "Command" : nil,
            (modifiers & UInt32(shiftKey) != 0) ? "Shift" : nil,
        ].compactMap { $0 }

        let key = keyCodeToString(keyCode)
        return (modifierDescriptions + [key]).joined(separator: " + ")
    }

    func resetToDefault() {
        keyCode = defaultKeyCode
        modifiers = defaultModifiers
    }

    private func keyCodeToString(_ keyCode: UInt32) -> String {
        switch keyCode {
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_B): return "B"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_D): return "D"
        case UInt32(kVK_ANSI_E): return "E"
        case UInt32(kVK_ANSI_F): return "F"
        case UInt32(kVK_ANSI_G): return "G"
        case UInt32(kVK_ANSI_H): return "H"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_J): return "J"
        case UInt32(kVK_ANSI_K): return "K"
        case UInt32(kVK_ANSI_L): return "L"
        case UInt32(kVK_ANSI_M): return "M"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_O): return "O"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_Q): return "Q"
        case UInt32(kVK_ANSI_R): return "R"
        case UInt32(kVK_ANSI_S): return "S"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_U): return "U"
        case UInt32(kVK_ANSI_V): return "V"
        case UInt32(kVK_ANSI_W): return "W"
        case UInt32(kVK_ANSI_X): return "X"
        case UInt32(kVK_ANSI_Y): return "Y"
        case UInt32(kVK_ANSI_Z): return "Z"
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        default: return "?"
        }
    }
}
