import SwiftUI

/// 공개된 사용자의 기록 공간 둘러보기 (docs/11 6장 Public Profile View).
struct PublicProfileView: View {
    let user: UserPublicProfile

    @EnvironmentObject private var socialRepository: SocialRepository
    @State private var toastMessage: String?

    var body: some View {
        let relation = socialRepository.relation(with: user.userId)
        let entries = socialRepository.entries(byAuthor: user.userId)

        ScrollView {
            VStack(spacing: AppLayout.largeGap) {
                VStack(spacing: AppLayout.smallGap) {
                    ZStack {
                        Circle().fill(AppColors.primary.opacity(0.12))
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.primary)
                    }
                    .frame(width: 72, height: 72)

                    Text(user.nickname)
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.text)
                    Text(user.spaceName)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textMuted)
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    Text("공개 기록 \(user.recordCountPublic)개")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)

                    friendActionButton(relation)
                        .padding(.top, 4)
                }
                .padding(.top, AppLayout.largeGap)

                if entries.isEmpty {
                    EmptyStateView(iconName: "square.and.pencil", title: "아직 공개한 기록이 없어요")
                } else {
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("공개 기록")
                            .font(AppTypography.headline)
                        ForEach(entries) { entry in
                            SocialEntryCard(entry: entry, toastMessage: $toastMessage)
                        }
                    }
                    .padding(.horizontal, AppLayout.horizontalPadding)
                }
            }
            .padding(.bottom, AppLayout.largeGap)
        }
        .background(AppColors.bg)
        .navigationTitle(user.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        socialRepository.report(targetType: "user", targetId: user.userId, reason: "inappropriate")
                        toastMessage = "신고가 접수됐어요."
                    } label: {
                        Label("신고하기", systemImage: "exclamationmark.bubble")
                    }
                    Button(role: .destructive) {
                        socialRepository.block(userId: user.userId)
                        toastMessage = "차단했어요."
                    } label: {
                        Label("차단하기", systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .toast(message: $toastMessage)
    }

    @ViewBuilder
    private func friendActionButton(_ relation: FriendRelation) -> some View {
        Button {
            switch relation {
            case .notFriends:
                socialRepository.sendRequest(to: user.userId)
                toastMessage = "친구 요청을 보냈어요."
            case .requestReceived:
                if let request = socialRepository.receivedRequests.first(where: { $0.requesterId == user.userId }) {
                    socialRepository.accept(request)
                    toastMessage = "친구가 됐어요."
                }
            default:
                break
            }
        } label: {
            Text(relation.buttonTitle)
                .font(AppTypography.callout)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(relation == .notFriends || relation == .requestReceived ? AppColors.primary : AppColors.surfaceAlt)
                .foregroundStyle(relation == .notFriends || relation == .requestReceived ? AppColors.primaryText : AppColors.textMuted)
                .clipShape(Capsule())
        }
        .disabled(relation == .requestSent || relation == .friends || relation == .blocked)
    }
}
