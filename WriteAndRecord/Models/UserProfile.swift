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

    /// 로즈·올리브 팔레트 테마.
    static let defaultThemes: [ProfileTheme] = [
        ProfileTheme(id: "deep-rose", name: "로즈", primaryColorHex: "#A4565C", backgroundStyle: .solid, fontStyle: .calm),
        ProfileTheme(id: "blush", name: "블러시", primaryColorHex: "#E7B4B9", backgroundStyle: .gradient, fontStyle: .cute),
        ProfileTheme(id: "light-pink", name: "라이트 핑크", primaryColorHex: "#FDE5E8", backgroundStyle: .solid, fontStyle: .cute),
        ProfileTheme(id: "olive", name: "올리브", primaryColorHex: "#999D4F", backgroundStyle: .solid, fontStyle: .minimal),
        ProfileTheme(id: "lime-cream", name: "라임", primaryColorHex: "#E8F0A2", backgroundStyle: .solid, fontStyle: .calm),
        ProfileTheme(id: "rose-ink", name: "잉크", primaryColorHex: "#43282B", backgroundStyle: .solid, fontStyle: .editorial)
    ]

    static func theme(for id: String) -> ProfileTheme {
        defaultThemes.first { $0.id == id } ?? defaultThemes[0]
    }
}
