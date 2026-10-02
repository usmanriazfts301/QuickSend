import SwiftUI
import Observation

// MARK: - App themes (Wise design language, remapped)

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case iris, lime, cobalt, ember
    var id: String { rawValue }
    var label: String {
        switch self {
        case .iris: return "Iris"
        case .lime: return "Wise Lime"
        case .cobalt: return "Cobalt"
        case .ember: return "Ember"
        }
    }
    var blurb: String {
        switch self {
        case .iris: return "Soft and friendly — purple all the way through."
        case .lime: return "The classic Wise pairing: lime on forest."
        case .cobalt: return "Deep blue confidence."
        case .ember: return "Warm coral energy."
        }
    }
}

struct ThemeColors {
    let accent: Color      // primary action fill (lime / iris CTA)
    let deep: Color        // forest ink — text on light, fills on dark
    let ink: Color         // near-black body text
    let canvas: Color      // app background tint
    let card: Color        // card surface (always white)
    let secondaryBg: Color // tinted control backgrounds
    let hair: Color        // hairline borders
    let onAccent: Color    // text on accent fill
    let textSecondary: Color
    let danger: Color
    let success: Color
    let warning: Color
}

extension AppTheme {
    var colors: ThemeColors {
        switch self {
        case .iris:
            return ThemeColors(
                accent: Color(hex: 0x8B7CFF), deep: Color(hex: 0x3B2A8F),
                ink: Color(hex: 0x1F1A44), canvas: Color(hex: 0xF2EEFD),
                card: .white, secondaryBg: Color(hex: 0x8B7CFF, alpha: 0.12),
                hair: Color(hex: 0x1F1A44, alpha: 0.14), onAccent: .white,
                textSecondary: Color(hex: 0x4E476E), danger: Color(hex: 0xD03238),
                success: Color(hex: 0x15803D), warning: Color(hex: 0xB45309))
        case .lime:
            return ThemeColors(
                accent: Color(hex: 0x9FE870), deep: Color(hex: 0x163300),
                ink: Color(hex: 0x0E0F0C), canvas: Color(hex: 0xE8EBE6),
                card: .white, secondaryBg: Color(hex: 0x163300, alpha: 0.08),
                hair: Color(hex: 0x0E0F0C, alpha: 0.12), onAccent: Color(hex: 0x163300),
                textSecondary: Color(hex: 0x454745), danger: Color(hex: 0xD03238),
                success: Color(hex: 0x054D28), warning: Color(hex: 0x7A5B00))
        case .cobalt:
            return ThemeColors(
                accent: Color(hex: 0x2E5BFF), deep: Color(hex: 0x0B2464),
                ink: Color(hex: 0x0A1830), canvas: Color(hex: 0xE9EEFB),
                card: .white, secondaryBg: Color(hex: 0x2E5BFF, alpha: 0.09),
                hair: Color(hex: 0x0A1830, alpha: 0.14), onAccent: .white,
                textSecondary: Color(hex: 0x3E4A63), danger: Color(hex: 0xD03238),
                success: Color(hex: 0x15803D), warning: Color(hex: 0xB45309))
        case .ember:
            return ThemeColors(
                accent: Color(hex: 0xFF5A36), deep: Color(hex: 0x4A1A0C),
                ink: Color(hex: 0x221206), canvas: Color(hex: 0xFAEEE5),
                card: .white, secondaryBg: Color(hex: 0xFF5A36, alpha: 0.10),
                hair: Color(hex: 0x221206, alpha: 0.14), onAccent: .white,
                textSecondary: Color(hex: 0x5C463A), danger: Color(hex: 0xD03238),
                success: Color(hex: 0x15803D), warning: Color(hex: 0xB45309))
        }
    }
}

/// Observable theme holder — swap `current` and the whole UI re-themes.
@Observable
final class ThemeManager {
    var current: AppTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "qs-theme")
        }
    }
    var colors: ThemeColors { current.colors }

    init() {
        let raw = UserDefaults.standard.string(forKey: "qs-theme") ?? AppTheme.iris.rawValue
        current = AppTheme(rawValue: raw) ?? .iris
    }
    func set(_ t: AppTheme) { current = t }
}

// MARK: - Hex helper

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

// MARK: - Wise type

extension Font {
    /// Wise display: ultra-heavy, tight tracking. Falls back to system heavy.
    static func wiseDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default)
    }
}
