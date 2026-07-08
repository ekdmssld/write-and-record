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

/// 색상 토큰 — 세이지·린넨 팔레트 (따뜻한 배경, 차분한 액션).
/// 기준 팔레트:
///   Milk Foam #FAF6F1 · Vanilla Linen #F2E6D8 · Oat Latte #DCD4C1
///   Savory Sage #818263 · Avocado Smooth #C2C395
enum AppColors {
    static let bg = Color(hex: "#FAF6F1")          // milk foam
    static let surface = Color(hex: "#FFFFFF")
    static let surfaceAlt = Color(hex: "#F2E6D8")  // vanilla linen
    static let text = Color(hex: "#3F3B32")        // readable warm charcoal
    static let textMuted = Color(hex: "#818263")   // savory sage
    static let line = Color(hex: "#DCD4C1")        // oat latte
    static let primary = Color(hex: "#818263")     // savory sage
    static let primaryText = Color(hex: "#FAF6F1")
    static let danger = Color(hex: "#9E5F55")      // muted blush warning
    static let success = Color(hex: "#C2C395")     // avocado smooth
    /// 별점 등 포인트 골드. 세이지 팔레트와 충돌하지 않는 낮은 채도의 골드.
    static let star = Color(hex: "#B89B5E")

    static func category(_ hexString: String) -> Color {
        Color(hex: hexString)
    }
}
