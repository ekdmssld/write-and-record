import SwiftUI

extension Color {
    /// "#RRGGBB" hex 문자열로 Color 생성.
    init(hex: String) {
        var value: UInt64 = 0
        var cleaned = hex.trimmingCharacters(in: .whitespaces)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// Design Spec 2장 색상 토큰. 라이트 모드 우선.
enum AppColors {
    static let bg = Color(hex: "#FBFAF7")
    static let surface = Color(hex: "#FFFFFF")
    static let surfaceAlt = Color(hex: "#F3F0EA")
    static let text = Color(hex: "#1F1F1F")
    static let textMuted = Color(hex: "#73706A")
    static let line = Color(hex: "#E7E1D8")
    static let primary = Color(hex: "#5B6CFF")
    static let primaryText = Color(hex: "#FFFFFF")
    static let danger = Color(hex: "#D94A4A")
    static let success = Color(hex: "#2E8B57")

    static func category(_ hexString: String) -> Color {
        Color(hex: hexString)
    }
}
