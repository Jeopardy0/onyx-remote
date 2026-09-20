import SwiftUI

/// Color tokens from the design spec. No pure UIKit/system colors —
/// everything the UI draws should come through here so the palette stays
/// centralized.
enum Palette {
    static let background = Color(hex: 0x0F1216)
    static let surface = Color(hex: 0x171B21)
    static let raised = Color(hex: 0x1F242C)
    static let border = Color(hex: 0x262D36)
    static let text = Color(hex: 0xE9EDF2)
    static let muted = Color(hex: 0x98A2B0)
    static let accent = Color(hex: 0xF2A93B)
    static let onAccent = Color(hex: 0x1A1204)
    static let danger = Color(hex: 0xFF6B5E)
    static let success = Color(hex: 0x4CC38A)

    enum FixtureType {
        static let wash = Color(hex: 0x4FC3B8)
        static let mover = Color(hex: 0xA99BFF)
        static let bar = Color(hex: 0xFF9A86)
        static let other = Color(hex: 0xBCC5D1)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
