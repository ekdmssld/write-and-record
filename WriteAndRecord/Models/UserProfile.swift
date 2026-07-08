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

    /// 세이지·린넨 팔레트 테마.
    static let defaultThemes: [ProfileTheme] = [
        ProfileTheme(id: "savory-sage", name: "세이지", primaryColorHex: "#818263", backgroundStyle: .solid, fontStyle: .calm),
        ProfileTheme(id: "avocado-smooth", name: "아보카도", primaryColorHex: "#C2C395", backgroundStyle: .solid, fontStyle: .minimal),
        ProfileTheme(id: "vanilla-linen", name: "바닐라 린넨", primaryColorHex: "#F2E6D8", backgroundStyle: .solid, fontStyle: .calm),
        ProfileTheme(id: "oat-latte", name: "오트 라떼", primaryColorHex: "#DCD4C1", backgroundStyle: .solid, fontStyle: .editorial),
        ProfileTheme(id: "soft-peach", name: "소프트 피치", primaryColorHex: "#F7D8CC", backgroundStyle: .gradient, fontStyle: .cute),
        ProfileTheme(id: "metallic-silver", name: "실버", primaryColorHex: "#A4AAAA", backgroundStyle: .solid, fontStyle: .minimal)
    ]

    static func theme(for id: String) -> ProfileTheme {
        defaultThemes.first { $0.id == id } ?? defaultThemes[0]
    }
}
