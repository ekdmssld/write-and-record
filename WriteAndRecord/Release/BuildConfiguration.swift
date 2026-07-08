import Foundation

/// 빌드 설정 분리: Debug / PersonalRelease / BetaRelease / (StoreRelease는 Release 사용)
/// Xcode build configuration의 SWIFT_ACTIVE_COMPILATION_CONDITIONS로 결정된다.
enum BuildMode: String {
    case debug
    case personalRelease
    case betaRelease
    case storeRelease
}

enum BuildConfiguration {
    static var current: BuildMode {
        #if DEBUG
        return .debug
        #elseif PERSONAL_RELEASE
        return .personalRelease
        #elseif BETA_RELEASE
        return .betaRelease
        #else
        return .storeRelease
        #endif
    }

    static var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }
}
