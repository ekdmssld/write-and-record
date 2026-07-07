import SwiftUI

struct EntryDetailView: View {
    let entryId: String

    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var showDeleteConfirm = false
    @State private var toastMessage: String?

    private var entry: Entry? {
        entryRepository.entry(id: entryId)
    }

    var body: some View {
        Group {
            if let entry {
                detailContent(entry)
            } else {
                EmptyStateView(
                    iconName: "trash",
                    title: "삭제된 기록이에요"
                )
            }
        }
        .background(AppColors.bg)
        .navigationTitle("기록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let entry {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            router.push(.entryEditor(date: entry.date, categoryId: entry.categoryId, entryId: entry.id))
                        } label: {
                            Label("수정", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("기록 메뉴")
                }
            }
        }
        .confirmationDialog("이 기록을 삭제할까요?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                if let entry {
                    entryRepository.delete(entry)
                    router.pop()
                }
            }
            Button("취소", role: .cancel) { }
        }
        .toast(message: $toastMessage)
        .onAppear {
            if toastPendingAfterSave {
                toastMessage = "기록이 저장됐어요."
                toastPendingAfterSave = false
            }
        }
    }

    /// 에디터 -> 상세 전환 직후에만 저장 toast를 보여주기 위한 플래그.
    @AppStorage("pendingSaveToast") private var toastPendingAfterSave = false

    private func detailContent(_ entry: Entry) -> some View {
        let assets = entryRepository.assets(for: entry)
        let colorHex = categoryRepository.colorHex(forEntry: entry)

        return ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.largeGap) {
                // cover
                if let cover = entryRepository.coverAsset(for: entry) {
                    AssetThumbnailView(asset: cover, placeholderColorHex: colorHex)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                }

                // metadata row
                HStack(spacing: AppLayout.smallGap) {
                    if let category = categoryRepository.category(id: entry.categoryId) {
                        CategoryChip(category: category)
                    } else {
                        Text(entry.archivedCategoryName ?? "삭제된 카테고리")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                    Text(DateUtils.display(entry.date))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textMuted)
                    Spacer()
                }

                HStack(spacing: AppLayout.mediumGap) {
                    if let rating = entry.rating {
                        RatingDisplay(rating: rating)
                    }
                    if entry.isWishlist {
                        Label("위시", systemImage: "bookmark.fill")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.primary)
                    }
                    if let count = entry.count {
                        Label("\(count)회", systemImage: "number")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }

                Text(entry.title)
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.text)

                if !entry.body.isEmpty {
                    Text(entry.body)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.text)
                        .lineSpacing(4)
                }

                // media gallery
                if assets.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppLayout.smallGap) {
                            ForEach(assets) { asset in
                                AssetThumbnailView(asset: asset, placeholderColorHex: colorHex)
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                            }
                        }
                    }
                }

                listSection(title: "장점", systemImage: "hand.thumbsup", items: entry.pros, tint: AppColors.success)
                listSection(title: "단점", systemImage: "hand.thumbsdown", items: entry.cons, tint: AppColors.danger)
                listSection(title: "팁", systemImage: "lightbulb", items: entry.tips, tint: AppColors.primary)

                if let place = entry.place {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(place.name, systemImage: "mappin.and.ellipse")
                            .font(AppTypography.headline)
                        if let address = place.address {
                            Text(address)
                                .font(AppTypography.callout)
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                }

                if !entry.links.isEmpty {
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        ForEach(entry.links) { link in
                            if let url = URL(string: link.url) {
                                Link(destination: url) {
                                    Label(link.title ?? link.url, systemImage: "link")
                                        .font(AppTypography.callout)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }

                metadataDisplay(entry)

                // make card CTA
                PrimaryButton(title: "기록 카드 만들기") {
                    router.push(.recordCardPicker(entryId: entry.id))
                }
                .padding(.top, AppLayout.smallGap)
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.mediumGap)
        }
    }

    @ViewBuilder
    private func listSection(title: String, systemImage: String, items: [String], tint: Color) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                Label(title, systemImage: systemImage)
                    .font(AppTypography.headline)
                    .foregroundStyle(tint)
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        Text(item)
                    }
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.text)
                }
            }
        }
    }

    @ViewBuilder
    private func metadataDisplay(_ entry: Entry) -> some View {
        let mainType = categoryRepository.category(id: entry.categoryId)?.mainType ?? .custom
        let fields = MetadataField.fields(for: mainType).filter {
            !(entry.metadata[$0.key] ?? "").isEmpty
        }
        if !fields.isEmpty {
            VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                Text("상세 정보")
                    .font(AppTypography.headline)
                ForEach(fields) { field in
                    HStack(alignment: .top) {
                        Text(field.label)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textMuted)
                            .frame(width: 130, alignment: .leading)
                        Text(entry.metadata[field.key] ?? "")
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.text)
                    }
                }
            }
            .padding(AppLayout.mediumGap)
            .background(AppColors.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        }
    }
}
