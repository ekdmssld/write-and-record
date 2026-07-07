import SwiftUI

/// 사진 중심 그리드. 사진 없는 기록은 카테고리 색 텍스트 카드 placeholder.
struct GalleryView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        let entries = entryRepository.entriesByDateDescending()
        ScrollView {
            if entries.isEmpty {
                EmptyStateView(
                    iconName: "photo.on.rectangle",
                    title: "아직 기록이 없어요",
                    subtitle: "사진과 함께 기록을 남겨보세요."
                )
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(entries) { entry in
                        Button {
                            router.push(.entryDetail(entryId: entry.id))
                        } label: {
                            galleryCell(entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.vertical, AppLayout.smallGap)
            }
        }
    }

    @ViewBuilder
    private func galleryCell(_ entry: Entry) -> some View {
        let colorHex = categoryRepository.colorHex(forEntry: entry)
        ZStack {
            if let cover = entryRepository.coverAsset(for: entry) {
                AssetThumbnailView(asset: cover, placeholderColorHex: colorHex)
            } else {
                ZStack {
                    AppColors.category(colorHex).opacity(0.18)
                    Text(entry.title)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityLabel("\(entry.title), \(DateUtils.short(entry.date))")
    }
}
