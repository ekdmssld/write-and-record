import SwiftUI

/// 카드 렌더링에 필요한 데이터 스냅샷.
struct RecordCardContext {
    let entry: Entry
    let categoryName: String
    let categoryColorHex: String
    let coverImage: UIImage?
    /// 같은 날짜의 모든 사진 (여러 게시글/한 게시글 여러 사진 포함). 하루 모음 카드에 사용.
    var dayImages: [UIImage] = []
    /// 같은 날짜 기록들의 제목.
    var dayTitles: [String] = []
}

/// 1080x1350 (4:5) 카드. 프리뷰/export 공용 뷰 — 프리뷰는 축소 렌더링.
struct RecordCardView: View {
    let template: RecordCardTemplate
    let context: RecordCardContext

    /// 렌더링 기준 크기. ImageRenderer에서 scale을 곱해 1080x1350을 만든다.
    static let baseSize = CGSize(width: 360, height: 450)

    var body: some View {
        Group {
            switch template {
            case .minimalPhoto: minimalPhoto
            case .blogSnippet: blogSnippet
            case .ratingReview: ratingReview
            case .wishlist: wishlistCard
            case .placeMemory: placeMemory
            case .textDiary: textDiary
            case .dayCollage: dayCollage
            }
        }
        .frame(width: Self.baseSize.width, height: Self.baseSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryColor: Color {
        AppColors.category(context.categoryColorHex)
    }

    private var dateText: String {
        DateUtils.display(context.entry.date)
    }

    @ViewBuilder
    private var photoOrFallback: some View {
        if let image = context.coverImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                categoryColor.opacity(0.25)
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(categoryColor)
            }
        }
    }

    // MARK: - Templates

    private var minimalPhoto: some View {
        ZStack(alignment: .bottomLeading) {
            photoOrFallback
            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(dateText) · \(context.categoryName)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.85))
                Text(context.entry.title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(20)
        }
    }

    private var blogSnippet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(categoryColor)
                .frame(height: 8)
            VStack(alignment: .leading, spacing: 14) {
                Text(context.categoryName.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(categoryColor)
                Text(context.entry.title)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(3)
                Text(String(context.entry.body.prefix(120)))
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textMuted)
                    .lineSpacing(4)
                    .lineLimit(6)
                Spacer()
                Text(dateText)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(24)
        }
        .background(AppColors.surface)
    }

    private var ratingReview: some View {
        VStack(spacing: 0) {
            photoOrFallback
                .frame(height: 240)
                .clipped()
            VStack(alignment: .leading, spacing: 10) {
                Text(context.entry.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(2)
                if let rating = context.entry.rating {
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 15))
                                .foregroundStyle(AppColors.star)
                        }
                    }
                }
                ForEach(Array(context.entry.pros.prefix(2)), id: \.self) { pro in
                    Label(pro, systemImage: "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.success)
                        .lineLimit(1)
                }
                ForEach(Array(context.entry.cons.prefix(2)), id: \.self) { con in
                    Label(con, systemImage: "minus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.danger)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(dateText) · \(context.categoryName)")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(AppColors.surface)
        }
    }

    private var wishlistCard: some View {
        ZStack {
            categoryColor.opacity(0.12)
            VStack(spacing: 16) {
                HStack {
                    Label("WISHLIST", systemImage: "bookmark.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(categoryColor)
                        .clipShape(Capsule())
                    Spacer()
                }
                if context.coverImage != nil {
                    photoOrFallback
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(context.entry.title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                        .lineLimit(2)
                    if !context.entry.body.isEmpty {
                        Text(String(context.entry.body.prefix(80)))
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textMuted)
                            .lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Text(dateText)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(22)
        }
    }

    private var placeMemory: some View {
        ZStack(alignment: .bottom) {
            photoOrFallback
            VStack(alignment: .leading, spacing: 8) {
                Label(context.entry.place?.name ?? context.entry.title, systemImage: "mappin.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(dateText)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.85))
                if let tip = context.entry.tips.first {
                    Text("TIP. \(tip)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(.black.opacity(0.55))
        }
    }

    /// 한 날짜의 사진들을 연속 콜라주로 담는 카드.
    private var dayCollage: some View {
        let images = Array(context.dayImages.prefix(9))
        let titles = Array(context.dayTitles.prefix(3))

        return VStack(spacing: 0) {
            // header
            HStack(alignment: .firstTextBaseline) {
                Text(dateText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 7, height: 7)
                    Text(images.count > 1 ? "\(images.count)장의 순간" : context.categoryName)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)

            // photo collage
            collageGrid(images)
                .frame(maxHeight: .infinity)
                .clipped()

            // footer: 그날 기록 제목들
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(titles.enumerated()), id: \.offset) { _, title in
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.text)
                        .lineLimit(1)
                }
                if context.dayTitles.count > titles.count {
                    Text("외 \(context.dayTitles.count - titles.count)개의 기록")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(AppColors.surface)
    }

    @ViewBuilder
    private func collageGrid(_ images: [UIImage]) -> some View {
        if images.isEmpty {
            photoOrFallback
        } else {
            let columnsCount = images.count <= 1 ? 1 : (images.count <= 4 ? 2 : 3)
            let rows: [[UIImage]] = stride(from: 0, to: images.count, by: columnsCount).map {
                Array(images[$0..<min($0 + columnsCount, images.count)])
            }
            VStack(spacing: 2) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 2) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, image in
                            Color.clear
                                .overlay(
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                )
                                .clipped()
                        }
                    }
                }
            }
        }
    }

    private var textDiary: some View {
        ZStack {
            AppColors.bg
            // subtle pattern
            VStack(spacing: 26) {
                ForEach(0..<16, id: \.self) { _ in
                    Rectangle()
                        .fill(AppColors.line.opacity(0.5))
                        .frame(height: 1)
                }
            }
            .padding(.top, 60)
            VStack(alignment: .leading, spacing: 18) {
                Text(dateText)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textMuted)
                Text(context.entry.title)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                    .lineLimit(3)
                Text(String(context.entry.body.prefix(200)))
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.text.opacity(0.8))
                    .lineSpacing(6)
                    .lineLimit(8)
                Spacer()
                HStack {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 8, height: 8)
                    Text(context.categoryName)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .padding(26)
        }
    }
}
