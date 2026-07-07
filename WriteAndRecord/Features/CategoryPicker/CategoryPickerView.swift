import SwiftUI

/// "무엇을 기록할까요?" — 메인 카테고리 그리드 -> 세부 카테고리 -> EntryEditor.
struct CategoryPickerView: View {
    let date: Date

    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var searchText = ""
    @State private var selectedMain: EntryCategory?
    @State private var showCustomForm = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.largeGap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("무엇을 기록할까요?")
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.text)
                    Text(DateUtils.display(date))
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textMuted)
                }

                // 커스텀 카테고리 생성은 상단에 고정 노출
                Button {
                    showCustomForm = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primary)
                        Text("커스텀 카테고리 만들기")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.text)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(AppLayout.mediumGap)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                            .stroke(AppColors.line, lineWidth: 1)
                    )
                }
                .accessibilityLabel("커스텀 카테고리 만들기")

                searchField

                if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    searchResults
                } else if let selectedMain {
                    subcategorySection(selectedMain)
                } else {
                    mainCategoryGrid
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.mediumGap)
        }
        .background(AppColors.bg)
        .navigationTitle("카테고리 선택")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomForm) {
            CustomCategoryFormView(parentId: selectedMain?.id) { newCategory in
                openEditor(with: newCategory)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: AppLayout.smallGap) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textMuted)
            TextField("카테고리 검색", text: $searchText)
                .font(AppTypography.body)
        }
        .padding(12)
        .background(AppColors.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
    }

    private var searchResults: some View {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let matches = categoryRepository.activeCategories.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
        return VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            if matches.isEmpty {
                Text("검색 결과가 없어요")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
            } else {
                ForEach(matches) { category in
                    Button {
                        openEditor(with: category)
                    } label: {
                        CategoryChip(category: category)
                    }
                }
            }
        }
    }

    private var mainCategoryGrid: some View {
        LazyVGrid(columns: columns, spacing: AppLayout.mediumGap) {
            ForEach(categoryRepository.mainCategories) { category in
                Button {
                    withAnimation { selectedMain = category }
                } label: {
                    VStack(spacing: AppLayout.smallGap) {
                        Image(systemName: category.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(AppColors.category(category.colorHex))
                        Text(category.name)
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.text)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppLayout.largeGap)
                    .background(AppColors.category(category.colorHex).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                }
                .accessibilityLabel("\(category.name) 카테고리 선택")
            }
        }
    }

    private func subcategorySection(_ main: EntryCategory) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
            HStack {
                Button {
                    withAnimation { selectedMain = nil }
                } label: {
                    Label("전체 카테고리", systemImage: "chevron.left")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.primary)
                }
                Spacer()
            }

            CategoryChip(category: main, isSelected: true)

            // 메인 카테고리 자체로 바로 기록
            Button {
                openEditor(with: main)
            } label: {
                Text("'\(main.name)'(으)로 바로 기록하기")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.primary)
            }

            let subs = categoryRepository.subcategories(of: main)
            FlowLayoutChips(categories: subs) { category in
                openEditor(with: category)
            }
        }
    }

    private func openEditor(with category: EntryCategory) {
        router.push(.entryEditor(date: date, categoryId: category.id, entryId: nil))
    }
}

/// 세부 카테고리 chip 목록.
struct FlowLayoutChips: View {
    let categories: [EntryCategory]
    let onSelect: (EntryCategory) -> Void

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(categories) { category in
                Button {
                    onSelect(category)
                } label: {
                    CategoryChip(category: category)
                }
            }
        }
    }
}
