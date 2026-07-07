import SwiftUI

/// 타임라인/검색/날짜 목록에서 쓰는 기록 카드 행.
struct EntryCardView: View {
    let entry: Entry

    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository

    var body: some View {
        HStack(spacing: AppLayout.mediumGap) {
            coverView
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColors.category(categoryRepository.colorHex(forEntry: entry)))
                        .frame(width: 8, height: 8)
                    Text(categoryRepository.displayName(forEntry: entry))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                    Text(DateUtils.short(entry.date))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                HStack(spacing: 8) {
                    if let rating = entry.rating {
                        RatingDisplay(rating: rating)
                    }
                    if entry.isWishlist {
                        HStack(spacing: 2) {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 10))
                            Text("위시")
                                .font(AppTypography.caption)
                        }
                        .foregroundStyle(AppColors.primary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var coverView: some View {
        if let cover = entryRepository.coverAsset(for: entry) {
            AssetThumbnailView(asset: cover, placeholderColorHex: categoryRepository.colorHex(forEntry: entry))
        } else {
            ZStack {
                AppColors.category(categoryRepository.colorHex(forEntry: entry)).opacity(0.15)
                Image(systemName: categoryRepository.category(id: entry.categoryId)?.icon ?? "tag")
                    .foregroundStyle(AppColors.category(categoryRepository.colorHex(forEntry: entry)))
            }
        }
    }
}
