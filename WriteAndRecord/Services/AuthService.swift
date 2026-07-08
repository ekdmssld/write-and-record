import Foundation

struct AuthSession: Codable, Equatable {
    var userId: String
    var provider: AuthProvider
    var createdAt: Date
}

enum AuthError: Error, LocalizedError {
    case loginFailed
    case notSupported

    var errorDescription: String? {
        switch self {
        case .loginFailed: return "로그인에 실패했어요. 다시 시도해 주세요."
        case .notSupported: return "이 빌드에서는 지원하지 않는 로그인 방식이에요."
        }
    }
}

/// Apple 로그인으로 교체 가능하도록 provider를 protocol로 격리한다.
protocol AuthService {
    func restoreSession() -> AuthSession?
    func signIn(provider: AuthProvider) async throws -> AuthSession
    func signOut()
}

final class LocalAuthService: AuthService {
    private let sessionFile = "session"

    func restoreSession() -> AuthSession? {
        PersistenceStore.load(AuthSession.self, from: sessionFile)
    }

    func signIn(provider: AuthProvider) async throws -> AuthSession {
        switch provider {
        case .mock:
            guard FeatureFlags.enableMockAuth else { throw AuthError.notSupported }
            let session = AuthSession(userId: "mock-user", provider: .mock, createdAt: Date())
            PersistenceStore.save(session, to: sessionFile)
            return session
        case .apple, .email:
            // Apple Sign In / 이메일 로그인은 개발자 계정 준비 후 이 지점에서 실제 구현으로 교체한다.
            // 현재는 로컬 단일 사용자 세션을 만든다 (기기 = 사용자 1명 전제).
            let session = AuthSession(userId: "local-user", provider: provider, createdAt: Date())
            PersistenceStore.save(session, to: sessionFile)
            return session
        }
    }

    func signOut() {
        PersistenceStore.delete(sessionFile)
    }
}
