import SwiftUI

/// 별점 1~5, no rating 상태 지원. 같은 별을 다시 탭하면 해제.
struct RatingControl: View {
    @Binding var rating: Int?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= (rating ?? 0) ? "star.fill" : "star")
                    .font(.system(size: 24))
                    .foregroundStyle(star <= (rating ?? 0) ? AppColors.star : AppColors.line)
                    .onTapGesture {
                        if rating == star {
                            rating = nil
                        } else {
                            rating = star
                        }
                    }
                    .accessibilityLabel("별점 \(star)점")
                    .accessibilityAddTraits(star <= (rating ?? 0) ? [.isSelected] : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(rating.map { "별점 \($0)점" } ?? "별점 없음")
    }
}

/// 읽기 전용 별점 표시.
struct RatingDisplay: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: 12))
                    .foregroundStyle(star <= rating ? AppColors.star : AppColors.line)
            }
        }
        .accessibilityLabel("별점 \(rating)점")
    }
}

struct WishlistToggle: View {
    @Binding var isWishlist: Bool

    var body: some View {
        Button {
            isWishlist.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isWishlist ? "bookmark.fill" : "bookmark")
                Text("위시")
                    .font(AppTypography.callout)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isWishlist ? AppColors.primary.opacity(0.12) : AppColors.surfaceAlt)
            .foregroundStyle(isWishlist ? AppColors.primary : AppColors.textMuted)
            .clipShape(Capsule())
        }
        .accessibilityLabel(isWishlist ? "위시리스트에 추가됨" : "위시리스트에 추가")
    }
}
