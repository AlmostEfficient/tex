import Foundation
import Carbon

final class ShortcutPreference {
    static let shared = ShortcutPreference()

    private let keyCodeKey = "shortcut.keyCode"
    private let modifiersKey = "shortcut.modifiers"

    private let defaultKeyCode: UInt32 = UInt32(kVK_ANSI_T)
    private let defaultModifiers: UInt32 = UInt32(controlKey | optionKey | cmdKey)
    private let defaultDescription = "Control + Option + Command + T"

    var keyCode: UInt32 {
        get {
            let saved = UserDefaults.standard.integer(forKey: keyCodeKey)
            return saved == 0 ? defaultKeyCode : UInt32(saved)
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: keyCodeKey)
        }
    }

    var modifiers: UInt32 {
        get {
            let saved = UserDefaults.standard.integer(forKey: modifiersKey)
            return saved == 0 ? defaultModifiers : UInt32(saved)
        }
        set {
            UserDefaults.standard.set(Int(newValue), forKey: modifiersKey)
        }
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
