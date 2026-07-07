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

    static let defaultThemes: [ProfileTheme] = [
        ProfileTheme(id: "calm-lavender", name: "라벤더", primaryColorHex: "#5B6CFF", backgroundStyle: .solid, fontStyle: .calm),
        ProfileTheme(id: "warm-peach", name: "피치", primaryColorHex: "#F2A65A", backgroundStyle: .gradient, fontStyle: .cute),
        ProfileTheme(id: "editorial-ink", name: "잉크", primaryColorHex: "#1F1F1F", backgroundStyle: .solid, fontStyle: .editorial),
        ProfileTheme(id: "forest-green", name: "포레스트", primaryColorHex: "#2E8B57", backgroundStyle: .solid, fontStyle: .minimal),
        ProfileTheme(id: "rose-pink", name: "로즈", primaryColorHex: "#FF7AA2", backgroundStyle: .gradient, fontStyle: .cute),
        ProfileTheme(id: "sea-teal", name: "티일", primaryColorHex: "#50B9B0", backgroundStyle: .solid, fontStyle: .calm)
    ]

    static func theme(for id: String) -> ProfileTheme {
        defaultThemes.first { $0.id == id } ?? defaultThemes[0]
    }
}
