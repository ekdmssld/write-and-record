import Foundation

enum AuthProvider: String, Codable {
    case apple
    case email
    case mock
}

struct UserProfile: Codable, Identifiable, Equatable {
    var id: String
    var authProvider: AuthProvider
    var nickname: String
    var avatarAssetId: String?
    var spaceName: String
    var themeId: String
    var socialEnabled: Bool
    var friendShareEnabled: Bool
    var notificationEnabled: Bool
    var onboardingCompletedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    static func new(id: String = UUID().uuidString, provider: AuthProvider) -> UserProfile {
        let now = Date()
        return UserProfile(
            id: id,
            authProvider: provider,
            nickname: "",
            avatarAssetId: nil,
            spaceName: "",
            themeId: ProfileTheme.defaultThemes[0].id,
            socialEnabled: false,
            friendShareEnabled: false,
            notificationEnabled: false,
            onboardingCompletedAt: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}

enum ThemeBackgroundStyle: String, Codable {
    case solid
    case gradient
    case pattern
}

enum ThemeFontStyle: String, Codable {
    case calm
    case cute
    case editorial
    case minimal
}

struct ProfileTheme: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var primaryColorHex: String
    var backgroundStyle: ThemeBackgroundStyle
    var fontStyle: ThemeFontStyle

    /// 부드러운 파스텔 팔레트 테마.
    static let defaultThemes: [ProfileTheme] = [
        ProfileTheme(id: "high-country-rose", name: "로즈", primaryColorHex: "#A16879", backgroundStyle: .solid, fontStyle: .calm),
        ProfileTheme(id: "pink-stock", name: "핑크 스톡", primaryColorHex: "#DEADA9", backgroundStyle: .gradient, fontStyle: .cute),
        ProfileTheme(id: "bourguignon", name: "버건디", primaryColorHex: "#BB737E", backgroundStyle: .solid, fontStyle: .editorial),
        ProfileTheme(id: "dried-palm", name: "팜", primaryColorHex: "#D9BE7A", backgroundStyle: .solid, fontStyle: .minimal),
        ProfileTheme(id: "beach-dune", name: "듄", primaryColorHex: "#C5BA9A", backgroundStyle: .solid, fontStyle: .calm),
        ProfileTheme(id: "warm-ink", name: "잉크", primaryColorHex: "#3D3330", backgroundStyle: .solid, fontStyle: .editorial)
    ]

    static func theme(for id: String) -> ProfileTheme {
        defaultThemes.first { $0.id == id } ?? defaultThemes[0]
    }
}
