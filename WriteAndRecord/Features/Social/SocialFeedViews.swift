import SwiftUI

/// 전체 탭: 공개 사용자 + 공개 기록 둘러보기 (docs/11 3장).
struct SocialAllTabView: View {
    @EnvironmentObject private var socialRepository: SocialRepository
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository

    @State private var toastMessage: String?

    var body: some View {
        let users = socialRepository.visiblePublicProfiles()
        let feed = socialRepository.publicFeed(
            myEntries: entryRepository.activeEntries,
            categories: categoryRepository.categories,
            mediaAssets: entryRepository.mediaAssets
        )

        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                Text("공개된 기록 공간을 둘러봐요.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.top, AppLayout.smallGap)

                if users.isEmpty && feed.isEmpty {
                    EmptyStateView(
                        iconName: "globe",
                        title: "아직 공개된 기록이 많지 않아요",
                        subtitle: "내 기록은 공개로 바꾸기 전까지 여기 보이지 않아요."
                    )
                } else {
                    if !users.isEmpty {
                        Text("공개 사용자")
                            .font(AppTypography.headline)
                            .padding(.horizontal, AppLayout.horizontalPadding)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppLayout.smallGap) {
                                ForEach(users) { user in
                                    PublicUserCard(user: user, toastMessage: $toastMessage)
                                }
                            }
                            .padding(.horizontal, AppLayout.horizontalPadding)
                        }
                    }

                    if !feed.isEmpty {
                        Text("공개 기록")
                            .font(AppTypography.headline)
                            .padding(.horizontal, AppLayout.horizontalPadding)
                        VStack(spacing: AppLayout.smallGap) {
                            ForEach(feed) { entry in
                                SocialEntryCard(entry: entry, toastMessage: $toastMessage)
                            }
                        }
                        .padding(.horizontal, AppLayout.horizontalPadding)
                    }
                }
            }
            .padding(.bottom, AppLayout.largeGap)
        }
        .toast(message: $toastMessage)
    }
}

/// 공개 사용자 카드 (docs/11 3장).
struct PublicUserCard: View {
    let user: UserPublicProfile
    @Binding var toastMessage: String?

    @EnvironmentObject private var socialRepository: SocialRepository

    var body: some View {
        let relation = socialRepository.relation(with: user.userId)
        VStack(spacing: AppLayout.smallGap) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.12))
                Image(systemName: "person.fill")
                    .foregroundStyle(AppColors.primary)
            }
            .frame(width: 44, height: 44)

            VStack(spacing: 2) {
                Text(user.nickname)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                Text(user.spaceName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
                Text("공개 기록 \(user.recordCountPublic)개")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textMuted)
            }

            friendActionButton(relation)
        }
        .frame(width: 132)
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
        .contextMenu {
            moderationMenu
        }
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
                .font(AppTypography.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(relation == .notFriends || relation == .requestReceived ? AppColors.primary : AppColors.surfaceAlt)
                .foregroundStyle(relation == .notFriends || relation == .requestReceived ? AppColors.primaryText : AppColors.textMuted)
                .clipShape(Capsule())
        }
        .disabled(relation == .requestSent || relation == .friends || relation == .blocked)
        .accessibilityLabel("\(user.nickname) \(relation.buttonTitle)")
    }

    @ViewBuilder
    private var moderationMenu: some View {
        Button {
            socialRepository.report(targetType: "user", targetId: user.userId, reason: "inappropriate")
            toastMessage = "신고가 접수됐어요."
        } label: {
            Label("신고하기", systemImage: "exclamationmark.bubble")
        }
        Button(role: .destructive) {
            socialRepository.block(userId: user.userId)
            toastMessage = "차단했어요. 서로의 기록이 보이지 않아요."
        } label: {
            Label("차단하기", systemImage: "hand.raised")
        }
    }
}

/// 소셜 피드 기록 카드 (작성자 + 기록 요약).
struct SocialEntryCard: View {
    let entry: SocialEntry
    @Binding var toastMessage: String?

    @EnvironmentObject private var socialRepository: SocialRepository

    private var isMine: Bool {
        entry.authorId == socialRepository.myUserId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            // author row
            HStack(spacing: AppLayout.smallGap) {
                ZStack {
                    Circle().fill(AppColors.primary.opacity(0.12))
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.primary)
                }
                .frame(width: 24, height: 24)
                Text(isMine ? "나" : (socialRepository.profile(userId: entry.authorId)?.nickname ?? "사용자"))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.text)
                Text(DateUtils.short(entry.date))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                Spacer()
                Label(entry.visibility.displayName, systemImage: entry.visibility.iconName)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textMuted)
                if !isMine {
                    Menu {
                        Button {
                            socialRepository.report(targetType: "entry", targetId: entry.id, reason: "inappropriate")
                            toastMessage = "신고가 접수됐어요."
                        } label: {
                            Label("신고하기", systemImage: "exclamationmark.bubble")
                        }
                        Button(role: .destructive) {
                            socialRepository.block(userId: entry.authorId)
                            toastMessage = "차단했어요."
                        } label: {
                            Label("차단하기", systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(AppColors.textMuted)
                            .frame(width: 28, height: 28)
                    }
                    .accessibilityLabel("기록 메뉴")
                }
            }

            socialPhotoPreview

            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.category(entry.categoryColorHex))
                    .frame(width: 7, height: 7)
                Text(entry.categoryName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                if let rating = entry.rating {
                    RatingDisplay(rating: rating)
                }
            }

            Text(entry.title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.text)
                .lineLimit(1)

            if !entry.bodyPreview.isEmpty {
                Text(entry.bodyPreview)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(2)
            }
        }
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var socialPhotoPreview: some View {
        if let coverAsset = entry.coverAsset {
            AssetThumbnailView(asset: coverAsset, placeholderColorHex: entry.categoryColorHex)
                .frame(height: 176)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius - 4))
        } else {
            ZStack(alignment: .bottomLeading) {
                AppColors.category(entry.categoryColorHex)
                    .opacity(0.16)
                Image(systemName: entry.isWishlist ? "bookmark.fill" : "photo")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppColors.category(entry.categoryColorHex))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text("사진 기록")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .padding(AppLayout.smallGap)
            }
            .frame(height: 132)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius - 4))
        }
    }
}
