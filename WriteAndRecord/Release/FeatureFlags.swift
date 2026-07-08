import Foundation

/// Functional Spec 3장 feature flags.
/// Debug: mock/sample/feedback on.
/// PersonalRelease: mock off, sample off, card export on, cloud off.
/// BetaRelease: mock off, feedback on, crash reporting on.
enum FeatureFlags {
    static var enableMockAuth: Bool {
        BuildConfiguration.current == .debug
    }

    static var enableSampleData: Bool {
        BuildConfiguration.current == .debug
    }

    static var enableFriendFeatures: Bool {
        // 소셜은 아직 로컬 mock 단계 (docs/10 2장): Debug에서만 켠다.
        // 서버/공개 범위 검증이 준비되면 BetaRelease부터 단계적으로 연다.
        BuildConfiguration.current == .debug
    }

    static var enableCloudSync: Bool {
        false
    }

    static var enableCardExport: Bool {
        true
    }

    static var enableFeedback: Bool {
        switch BuildConfiguration.current {
        case .debug, .betaRelease: return true
        case .personalRelease, .storeRelease: return false
        }
    }

    static var enableCrashReporting: Bool {
        // BetaRelease에서 crash reporting SDK를 붙일 때 이 flag로 게이트한다.
        BuildConfiguration.current == .betaRelease
    }

    static var showDebugTools: Bool {
        BuildConfiguration.current == .debug
    }
}
