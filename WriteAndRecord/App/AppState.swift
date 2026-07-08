import Foundation
import Combine
import UIKit

/// 온보딩 중간 종료 대비 draft (Functional Spec 5장).
struct OnboardingDraft: Codable {
    var step: Int
    var profile: UserProfile
}

final class AppState: ObservableObject {
    enum RootRoute {
        case auth
        case onboarding
        case main
    }

    @Published var route: RootRoute = .auth
    @Published var session: AuthSession?
    @Published var profile: UserProfile?

    let authService: AuthService

    private let profileFile = "userProfile"
    private let onboardingDraftFile = "onboardingDraft"

    init(authService: AuthService = LocalAuthService()) {
        self.authService = authService
        restore()
    }

    /// 앱 시작 시 session/onboarding 상태 확인 (Flowchart 1).
    func restore() {
        session = authService.restoreSession()
        profile = PersistenceStore.load(UserProfile.self, from: profileFile)

        guard session != nil else {
            route = .auth
            return
        }
        if let profile, profile.onboardingCompletedAt != nil {
            route = .main
        } else {
            route = .onboarding
        }
    }

    func signIn(provider: AuthProvider) async throws {
        let newSession = try await authService.signIn(provider: provider)
        await MainActor.run {
            self.session = newSession
            if let profile = self.profile, profile.onboardingCompletedAt != nil {
                self.route = .main
            } else {
                self.route = .onboarding
            }
        }
    }

    /// 로그아웃: 로컬 데이터 유지/삭제 선택 (Functional Spec 4장).
    func signOut(deleteLocalData: Bool, entryRepository: EntryRepository, categoryRepository: CategoryRepository) {
        authService.signOut()
        session = nil
        if deleteLocalData {
            PersistenceStore.deleteAll()
            profile = nil
            entryRepository.resetAllData()
            categoryRepository.resetToDefaults()
        }
        route = .auth
    }

    // MARK: - Profile

    func saveProfile(_ newProfile: UserProfile) {
        var updated = newProfile
        updated.updatedAt = Date()
        profile = updated
        PersistenceStore.save(updated, to: profileFile)
    }

    func completeOnboarding(with newProfile: UserProfile) {
        var completed = newProfile
        completed.onboardingCompletedAt = Date()
        saveProfile(completed)
        clearOnboardingDraft()
        route = .main
    }

    // MARK: - Onboarding draft

    func saveOnboardingDraft(step: Int, profile: UserProfile) {
        PersistenceStore.save(OnboardingDraft(step: step, profile: profile), to: onboardingDraftFile)
    }

    func loadOnboardingDraft() -> OnboardingDraft? {
        PersistenceStore.load(OnboardingDraft.self, from: onboardingDraftFile)
    }

    func clearOnboardingDraft() {
        PersistenceStore.delete(onboardingDraftFile)
    }

    // MARK: - Avatar

    /// 프로필 사진은 앱 내부 파일로 저장한다 (사진첩 권한과 무관하게 유지).
    func saveAvatarImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let assetId = "avatar-\(UUID().uuidString)"
        let url = PersistenceStore.dataDirectory.appendingPathComponent("\(assetId).jpg")
        do {
            try data.write(to: url, options: [.atomic])
            return assetId
        } catch {
            return nil
        }
    }

    func loadAvatarImage(assetId: String?) -> UIImage? {
        guard let assetId else { return nil }
        let url = PersistenceStore.dataDirectory.appendingPathComponent("\(assetId).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
