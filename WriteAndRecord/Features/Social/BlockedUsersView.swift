import SwiftUI

/// 차단한 사용자 관리 (docs/11 10장: "Settings -> Blocked users에서 해제 가능").
struct BlockedUsersView: View {
    @EnvironmentObject private var socialRepository: SocialRepository

    @State private var toastMessage: String?

    var body: some View {
        Group {
            if socialRepository.blockedUserIds.isEmpty {
                EmptyStateView(
                    iconName: "hand.raised",
                    title: "차단한 사용자가 없어요"
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(socialRepository.blockedUserIds).sorted(), id: \.self) { userId in
                        HStack(spacing: AppLayout.mediumGap) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(socialRepository.profile(userId: userId)?.nickname ?? "알 수 없는 사용자")
                                    .font(AppTypography.headline)
                                    .foregroundStyle(AppColors.text)
                                if let spaceName = socialRepository.profile(userId: userId)?.spaceName {
                                    Text(spaceName)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.textMuted)
                                }
                            }
                            Spacer()
                            Button("차단 해제") {
                                socialRepository.unblock(userId: userId)
                                toastMessage = "차단을 해제했어요."
                            }
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.primary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(AppColors.bg)
        .navigationTitle("차단한 사용자")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: $toastMessage)
    }
}
