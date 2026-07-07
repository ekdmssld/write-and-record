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
        false // MVP: 설정값만 저장, 기능은 미노출
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
