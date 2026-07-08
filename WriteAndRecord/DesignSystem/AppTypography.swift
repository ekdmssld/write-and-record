import SwiftUI

/// Design Spec 3장 typography. iOS system font + Dynamic Type 대응을 위해
/// 고정 크기 대신 text style 기반 relative size를 사용한다.
enum AppTypography {
    static let largeTitle = Font.system(.largeTitle, weight: .semibold)
    static let title1 = Font.system(.title, weight: .semibold)
    static let title2 = Font.system(.title2, weight: .semibold)
    static let headline = Font.system(.headline, weight: .semibold)
    static let body = Font.system(.body)
    static let callout = Font.system(.callout)
    static let caption = Font.system(.caption)
}

enum AppLayout {
    static let horizontalPadding: CGFloat = 20
    static let smallGap: CGFloat = 8
    static let mediumGap: CGFloat = 12
    static let largeGap: CGFloat = 20
    static let cardRadius: CGFloat = 8
    static let buttonRadius: CGFloat = 10
}
