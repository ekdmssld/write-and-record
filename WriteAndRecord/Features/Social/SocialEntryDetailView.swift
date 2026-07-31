import SwiftUI

/// 소셜 기록 상세 (docs/11 7장). 친구/공개 기록을 읽되 내 개인 기록 상세와 혼동하지 않는다.
/// - 내 기록이면 실제 Entry를 조회해 전체 본문/사진을 보여준다.
/// - 다른 사용자 기록이면 SocialEntry에 담긴 미리보기(bodyPreview)까지만 보여준다 — 원본 비공개 원칙 유지.
struct SocialEntryDetailView: View {
    let entry: SocialEntry

    @EnvironmentObject private var socialRepository: SocialRepository
    @EnvironmentObject private var entryRepository: EntryRepository

    @State private var commentText = ""
    @State private var toastMessage: String?

    private var isMine: Bool {
        entry.authorId == socialRepository.myUserId
    }

    private var fullEntry: Entry? {
        isMine ? entryRepository.entry(id: entry.id) : nil
    }

    private var authorName: String {
        isMine ? "나" : (socialRepository.profile(userId: entry.authorId)?.nickname ?? "사용자")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                header
                photos
                categoryRow
                Text(fullEntry?.title ?? entry.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.text)
                Text(fullEntry?.body ?? entry.bodyPreview)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.text)
                reactionRow
                Divider().overlay(AppColors.line)
                commentsSection
            }
            .padding(AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.largeGap)
        }
        .background(AppColors.bg)
        .navigationTitle("기록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isMine {
                ToolbarItem(placement: .topBarTrailing) {
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
                    }
                }
            }
        }
        .toast(message: $toastMessage)
    }

    private var header: some View {
        HStack(spacing: AppLayout.smallGap) {
            ZStack {
                Circle().fill(AppColors.primary.opacity(0.12))
                Image(systemName: "person.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.primary)
            }
            .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(authorName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                Text(DateUtils.short(entry.date))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
            Label(entry.visibility.displayName, systemImage: entry.visibility.iconName)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)
        }
    }

    @ViewBuilder
    private var photos: some View {
        if let fullEntry, !fullEntry.assetIds.isEmpty {
            let assets = entryRepository.assets(for: fullEntry)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.smallGap) {
                    ForEach(assets) { asset in
                        AssetThumbnailView(asset: asset, placeholderColorHex: entry.categoryColorHex)
                            .frame(width: 220, height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                    }
                }
            }
        } else if let coverAsset = entry.coverAsset {
            AssetThumbnailView(asset: coverAsset, placeholderColorHex: entry.categoryColorHex)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        }
    }

    private var categoryRow: some View {
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
    }

    private var reactionRow: some View {
        HStack(spacing: AppLayout.largeGap) {
            Button {
                socialRepository.toggleLike(entryId: entry.id)
            } label: {
                let liked = socialRepository.hasLiked(entryId: entry.id)
                Label("\(socialRepository.likeCount(for: entry.id))", systemImage: liked ? "heart.fill" : "heart")
                    .foregroundStyle(liked ? AppColors.danger : AppColors.textMuted)
            }
            Label("\(socialRepository.commentCount(for: entry.id))", systemImage: "bubble.right")
                .foregroundStyle(AppColors.textMuted)
        }
        .font(AppTypography.callout)
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
            Text("댓글")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.text)

            let comments = socialRepository.comments(for: entry.id)
            if comments.isEmpty {
                Text("아직 댓글이 없어요. 첫 댓글을 남겨보세요.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
            } else {
                VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                    ForEach(comments) { comment in
                        commentRow(comment)
                    }
                }
            }

            commentInput
        }
    }

    private func commentRow(_ comment: SocialComment) -> some View {
        let isMineComment = comment.authorId == socialRepository.myUserId
        let name = isMineComment ? "나" : (socialRepository.profile(userId: comment.authorId)?.nickname ?? "사용자")
        return HStack(alignment: .top, spacing: AppLayout.smallGap) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.text)
                    Text(DateUtils.short(comment.createdAt))
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                }
                Text(comment.text)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.text)
            }
            Spacer()
            if isMineComment {
                Menu {
                    Button(role: .destructive) {
                        socialRepository.deleteComment(comment)
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(AppColors.textMuted)
                }
            } else {
                Menu {
                    Button {
                        socialRepository.report(targetType: "comment", targetId: comment.id, reason: "inappropriate")
                        toastMessage = "신고가 접수됐어요."
                    } label: {
                        Label("신고하기", systemImage: "exclamationmark.bubble")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(AppColors.textMuted)
                }
            }
        }
    }

    private var commentInput: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: AppLayout.smallGap) {
                TextField("댓글을 남겨보세요", text: $commentText, axis: .vertical)
                    .font(AppTypography.callout)
                    .padding(10)
                    .background(AppColors.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                Button("게시") {
                    if socialRepository.addComment(entryId: entry.id, text: commentText) {
                        commentText = ""
                    }
                }
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.primary)
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || commentText.count > 300)
            }
            if commentText.count > 300 {
                Text("300자까지만 쓸 수 있어요.")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.danger)
            }
        }
    }
}
