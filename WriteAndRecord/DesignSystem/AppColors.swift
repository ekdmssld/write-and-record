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

/// 색상 토큰 — 부드러운 파스텔 팔레트 (docs/09 방향: 따뜻한 배경, 또렷한 액션).
/// 기준 팔레트:
///   Dried Palm #E2DAAC · Beach Dune #C5BA9A · Pink Stock #DEADA9
///   Beef Bourguignon #BB737E · High Country Rose #A16879
enum AppColors {
    static let bg = Color(hex: "#FAF6ED")          // warm paper (dried palm 톤)
    static let surface = Color(hex: "#FFFFFF")
    static let surfaceAlt = Color(hex: "#F2ECDC")  // dried palm light
    static let text = Color(hex: "#3D3330")        // warm dark brown
    static let textMuted = Color(hex: "#8F8378")
    static let line = Color(hex: "#E6DDC9")
    static let primary = Color(hex: "#A16879")     // high country rose
    static let primaryText = Color(hex: "#FFFFFF")
    static let danger = Color(hex: "#C9605F")
    static let success = Color(hex: "#7A9B7E")
    /// 별점 등 포인트 골드.
    static let star = Color(hex: "#D2A85E")

    static func category(_ hexString: String) -> Color {
        Color(hex: hexString)
    }
}
