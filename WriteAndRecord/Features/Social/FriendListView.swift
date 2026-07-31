import SwiftUI

/// 친구 목록 전체보기 (docs/10 14장 P1 Social).
struct FriendListView: View {
    @EnvironmentObject private var socialRepository: SocialRepository

    @State private var query = ""
    @State private var toastMessage: String?

    private var filteredFriends: [UserPublicProfile] {
        let friends = socialRepository.friends()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return friends }
        return friends.filter {
            $0.nickname.localizedCaseInsensitiveContains(trimmed)
                || $0.spaceName.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        Group {
            if socialRepository.friends().isEmpty {
                EmptyStateView(
                    iconName: "person.2",
                    title: "아직 친구가 없어요",
                    subtitle: "닉네임으로 찾거나 초대 링크를 보내보세요."
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredFriends) { friend in
                        HStack(spacing: AppLayout.mediumGap) {
                            ZStack {
                                Circle().fill(AppColors.primary.opacity(0.12))
                                Image(systemName: "person.fill")
                                    .foregroundStyle(AppColors.primary)
                            }
                            .frame(width: 40, height: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(friend.nickname)
                                    .font(AppTypography.headline)
                                    .foregroundStyle(AppColors.text)
                                Text(friend.spaceName)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textMuted)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                socialRepository.removeFriend(userId: friend.userId)
                                toastMessage = "친구를 삭제했어요."
                            } label: {
                                Label("친구 삭제", systemImage: "person.badge.minus")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $query, prompt: "친구 검색")
            }
        }
        .background(AppColors.bg)
        .navigationTitle("친구 목록")
        .navigationBarTitleDisplayMode(.inline)
        .toast(message: $toastMessage)
    }
}
