import SwiftUI

/// 검색/필터: 제목/본문/카테고리/장소/링크 텍스트 + 카테고리/별점/위시/사진/장소 필터.
/// 라이브러리 우측 상단 검색 버튼에서 push되어 열린다.
struct SearchView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var filter = EntryRepository.SearchFilter()

    private var results: [Entry] {
        entryRepository.search(filter, categories: categoryRepository.categories)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            filterBar
            Divider().overlay(AppColors.line)
            resultList
        }
        .background(AppColors.bg)
        .navigationTitle("검색")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchField: some View {
        HStack(spacing: AppLayout.smallGap) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textMuted)
            TextField("제목, 내용, 카테고리, 장소, 링크 검색", text: $filter.text)
                .font(AppTypography.body)
            if !filter.text.isEmpty {
                Button {
                    filter.text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textMuted)
                }
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(12)
        .background(AppColors.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.vertical, AppLayout.smallGap)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.smallGap) {
                Menu {
                    Button("전체 카테고리") { filter.categoryId = nil }
                    ForEach(categoryRepository.mainCategories) { category in
                        Button(category.name) { filter.categoryId = category.id }
                    }
                } label: {
                    chipLabel(
                        title: filter.categoryId.flatMap { categoryRepository.category(id: $0)?.name } ?? "카테고리",
                        isOn: filter.categoryId != nil
                    )
                }

                Menu {
                    Button("전체 별점") { filter.minRating = nil }
                    ForEach((1...5).reversed(), id: \.self) { rating in
                        Button("★ \(rating)점 이상") { filter.minRating = rating }
                    }
                } label: {
                    chipLabel(
                        title: filter.minRating.map { "★ \($0)+" } ?? "별점",
                        isOn: filter.minRating != nil
                    )
                }

                Button { filter.wishlistOnly.toggle() } label: {
                    chipLabel(title: "위시", isOn: filter.wishlistOnly)
                }
                Button { filter.hasPhotoOnly.toggle() } label: {
                    chipLabel(title: "사진 있음", isOn: filter.hasPhotoOnly)
                }
                Button { filter.hasPlaceOnly.toggle() } label: {
                    chipLabel(title: "장소 있음", isOn: filter.hasPlaceOnly)
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.smallGap)
        }
    }

    private func chipLabel(title: String, isOn: Bool) -> some View {
        Text(title)
            .font(AppTypography.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isOn ? AppColors.primary.opacity(0.12) : AppColors.surfaceAlt)
            .foregroundStyle(isOn ? AppColors.primary : AppColors.textMuted)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var resultList: some View {
        if results.isEmpty {
            ScrollView {
                EmptyStateView(
                    iconName: "magnifyingglass",
                    title: filter.isEmpty ? "기록을 검색해 보세요" : "검색 결과가 없어요",
                    subtitle: filter.isEmpty ? "제목, 내용, 카테고리, 장소로 찾을 수 있어요." : "다른 검색어나 필터를 써보세요."
                )
            }
        } else {
            ScrollView {
                LazyVStack(spacing: AppLayout.smallGap) {
                    ForEach(results) { entry in
                        Button {
                            router.push(.entryDetail(entryId: entry.id))
                        } label: {
                            EntryCardView(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.vertical, AppLayout.mediumGap)
            }
        }
    }
}
