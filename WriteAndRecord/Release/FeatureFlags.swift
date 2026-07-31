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
        // 소셜 P0+P1 기능(공개범위/차단·신고/친구 관리/좋아요·댓글)이 준비되어
        // BetaRelease부터 연다. PersonalRelease는 개인 전용 빌드라 계속 off (docs/10 2장).
        // 서버가 없어 실제 다중 사용자 간 소셜(친구 검색/초대 수락)은 여전히 동작하지 않는다 —
        // 이 플래그는 UI/설정/좋아요·댓글 레이어의 노출 여부만 결정한다.
        switch BuildConfiguration.current {
        case .debug, .betaRelease, .storeRelease: return true
        case .personalRelease: return false
        }
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
