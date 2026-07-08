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

    /// 사진 전체 배경 + 큰 날짜 오버레이 에디토리얼 스타일.
    private var minimalPhoto: some View {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: context.entry.date)
        let daysInMonth = calendar.range(of: .day, in: .month, for: context.entry.date)?.count ?? 30
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "en_US")
        monthFormatter.dateFormat = "MMM"
        let monthShort = monthFormatter.string(from: context.entry.date).uppercased()

        return ZStack {
            photoOrFallback
            LinearGradient(
                colors: [.black.opacity(0.35), .clear, .black.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack {
                // 좌상단 큰 날짜
                HStack {
                    VStack(alignment: .leading, spacing: -4) {
                        Text("\(day)")
                            .font(.system(size: 44, weight: .semibold))
                        Text(monthShort)
                            .font(.system(size: 15, weight: .medium))
                            .tracking(2)
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    Spacer()
                }
                Spacer()
                // 좌하단 제목 + 진행 표기
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.entry.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(day)/\(daysInMonth)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                            Rectangle()
                                .fill(.white.opacity(0.85))
                                .frame(width: 44, height: 1.5)
                        }
                    }
                    Spacer()
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 10, height: 10)
                }
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

    /// 한 날짜의 사진들을 폴라로이드 스택으로 담는 카드.
    /// 사진 카드가 겹치며 펼쳐지고, 넘치는 장수는 "+N" 카드로 표시한다.
    private var dayCollage: some View {
        let allImages = context.dayImages
        let shown = Array(allImages.prefix(3))
        let overflow = allImages.count - shown.count
        let rotations: [Double] = [-7, 3, -2]
        let title = context.dayTitles.first ?? context.entry.title

        return ZStack {
            AppColors.bg
            VStack(spacing: 24) {
                Spacer()

                if shown.isEmpty {
                    polaroidCard { AnyView(photoOrFallback) }
                } else {
                    HStack(spacing: -34) {
                        ForEach(Array(shown.enumerated()), id: \.offset) { index, image in
                            polaroidCard {
                                AnyView(
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                )
                            }
                            .rotationEffect(.degrees(rotations[index % rotations.count]))
                            .zIndex(Double(index))
                        }
                        if overflow > 0 {
                            polaroidCard {
                                AnyView(
                                    ZStack {
                                        AppColors.surfaceAlt
                                        Text("+\(overflow)")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundStyle(AppColors.text)
                                    }
                                )
                            }
                            .rotationEffect(.degrees(6))
                            .zIndex(Double(shown.count))
                        }
                    }
                    .padding(.horizontal, 12)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(dateText)
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textMuted)
                    if context.dayTitles.count > 1 {
                        Text("외 \(context.dayTitles.count - 1)개의 기록")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    /// 흰 테두리 폴라로이드 프레임.
    private func polaroidCard(content: () -> AnyView) -> some View {
        content()
            .frame(width: 116, height: 156)
            .clipped()
            .padding(.top, 7)
            .padding(.horizontal, 7)
            .padding(.bottom, 22)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
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
