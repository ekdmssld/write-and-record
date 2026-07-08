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

/// 색상 토큰 — 로즈·올리브 팔레트 (docs/09 방향: 따뜻한 배경, 또렷한 액션).
/// 기준 팔레트:
///   Light Pink #FDE5E8 · Blush #E7B4B9 · Deep Rose #A4565C
///   Lime Cream #E8F0A2 · Olive #999D4F
enum AppColors {
    static let bg = Color(hex: "#FDE5E8")          // light pink paper
    static let surface = Color(hex: "#FFFFFF")
    static let surfaceAlt = Color(hex: "#FBD9DD")  // blush light (파생)
    static let text = Color(hex: "#43282B")        // deep rose를 어둡게 (파생)
    static let textMuted = Color(hex: "#9A7378")
    static let line = Color(hex: "#EFC6CB")
    static let primary = Color(hex: "#A4565C")     // deep rose
    static let primaryText = Color(hex: "#FFFFFF")
    static let danger = Color(hex: "#C94F46")
    static let success = Color(hex: "#999D4F")     // olive
    /// 별점 등 포인트 골드.
    static let star = Color(hex: "#D2B25E")

    static func category(_ hexString: String) -> Color {
        Color(hex: hexString)
    }
}
