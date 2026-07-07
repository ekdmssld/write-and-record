import SwiftUI

/// 온보딩 4단계: 닉네임 -> 프로필 사진 -> 테마+공간 이름 -> 소개+소셜 설정.
/// 중간 종료 시 draft를 저장하고, 재실행 시 마지막 단계부터 이어간다.
struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    @State private var step = 0
    @State private var draftProfile: UserProfile = .new(provider: .mock)

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // progress
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? AppColors.primary : AppColors.line)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.top, AppLayout.mediumGap)
            .accessibilityLabel("온보딩 \(step + 1)단계, 총 \(totalSteps)단계")

            TabView(selection: $step) {
                OnboardingNicknameView(profile: $draftProfile, onNext: goNext)
                    .tag(0)
                OnboardingPhotoView(profile: $draftProfile, onNext: goNext)
                    .tag(1)
                OnboardingThemeView(profile: $draftProfile, onNext: goNext)
                    .tag(2)
                OnboardingIntroSocialView(profile: $draftProfile, onStart: finish)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)
        }
        .background(AppColors.bg)
        .onAppear(perform: restoreDraft)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                appState.saveOnboardingDraft(step: step, profile: draftProfile)
            }
        }
    }

    private func restoreDraft() {
        if let draft = appState.loadOnboardingDraft() {
            draftProfile = draft.profile
            step = min(draft.step, totalSteps - 1)
        } else {
            var profile = appState.profile ?? .new(provider: appState.session?.provider ?? .mock)
            if let session = appState.session {
                profile.id = session.userId
                profile.authProvider = session.provider
            }
            draftProfile = profile
        }
    }

    private func goNext() {
        let next = min(step + 1, totalSteps - 1)
        step = next
        appState.saveOnboardingDraft(step: next, profile: draftProfile)
    }

    private func finish() {
        appState.completeOnboarding(with: draftProfile)
    }
}

/// 온보딩 공용 레이아웃: 한 화면 한 결정, 여백 넓게.
struct OnboardingStepContainer<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.largeGap) {
            VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                Text(title)
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.text)
                if let subtitle {
                    Text(subtitle)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .padding(.top, 40)

            content

            Spacer()
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
    }
}
