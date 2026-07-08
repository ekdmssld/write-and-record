import SwiftUI

/// 소셜 탭 루트 (docs/11).
/// - socialEnabled가 꺼져 있으면 opt-in 인트로를 먼저 보여준다.
/// - 켜져 있으면 상단 `전체 / 친구들 / 추가` 세그먼트로 전환한다.
struct SocialView: View {
    @EnvironmentObject private var appState: AppState

    enum SocialTab: String, CaseIterable, Identifiable {
        case all = "전체"
        case friendsTab = "친구들"
        case add = "추가"

        var id: String { rawValue }
    }

    @State private var tab: SocialTab = .all

    private var socialEnabled: Bool {
        appState.profile?.socialEnabled ?? false
    }

    var body: some View {
        NavigationStack {
            Group {
                if !FeatureFlags.enableFriendFeatures {
                    SocialComingSoonView()
                } else if !socialEnabled {
                    SocialIntroView {
                        enableSocial()
                    }
                } else {
                    VStack(spacing: 0) {
                        tabBar
                        Divider().overlay(AppColors.line)
                        switch tab {
                        case .all:
                            SocialAllTabView()
                        case .friendsTab:
                            SocialFriendsTabView(onGoToAdd: { tab = .add })
                        case .add:
                            SocialAddTabView()
                        }
                    }
                }
            }
            .background(AppColors.bg)
            .navigationTitle("소셜")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var tabBar: some View {
        HStack(spacing: AppLayout.smallGap) {
            ForEach(SocialTab.allCases) { item in
                Button {
                    tab = item
                } label: {
                    Text(item.rawValue)
                        .font(AppTypography.callout)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(tab == item ? AppColors.text : AppColors.surfaceAlt)
                        .foregroundStyle(tab == item ? AppColors.surface : AppColors.textMuted)
                        .clipShape(Capsule())
                }
                .accessibilityLabel("\(item.rawValue) 탭\(tab == item ? ", 선택됨" : "")")
            }
            Spacer()
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.vertical, AppLayout.smallGap)
    }

    private func enableSocial() {
        guard var profile = appState.profile else { return }
        profile.socialEnabled = true
        appState.saveProfile(profile)
    }
}

/// 소셜 opt-in 인트로 (docs/11 1장). 기본 비공개 원칙을 먼저 말한다.
struct SocialIntroView: View {
    let onEnable: () -> Void

    var body: some View {
        VStack(spacing: AppLayout.largeGap) {
            Spacer()
            Image(systemName: "person.2.circle")
                .font(.system(size: 52))
                .foregroundStyle(AppColors.primary)
            VStack(spacing: AppLayout.smallGap) {
                Text("친구와 기록을 나눠볼까요?")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.text)
                Text("기본적으로 내 기록은 나만 볼 수 있어요.\n공개하거나 친구에게 보여주기로 선택한 기록만\n소셜에 나타나요.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            VStack(spacing: AppLayout.smallGap) {
                PrimaryButton(title: "소셜 기능 켜기") {
                    onEnable()
                }
                Text("나중에 할게요")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.largeGap)
        }
    }
}

/// friend feature flag가 꺼진 빌드용 안내.
struct SocialComingSoonView: View {
    var body: some View {
        EmptyStateView(
            iconName: "person.2",
            title: "소셜 기능을 준비하고 있어요",
            subtitle: "기본적으로 모든 기록은 나만 볼 수 있어요.\n공개한 기록만 소셜에 보이게 될 거예요."
        )
        .frame(maxHeight: .infinity)
    }
}
