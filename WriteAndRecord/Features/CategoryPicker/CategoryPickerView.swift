import SwiftUI

/// "무엇을 기록할까요?" — 메인 카테고리 그리드 -> 세부 카테고리 -> EntryEditor.
struct CategoryPickerView: View {
    let date: Date

    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var searchText = ""
    @State private var selectedMain: EntryCategory?
    /// 최종 선택된 카테고리(메인 또는 세부). 하단 "기록하기" 버튼으로 진행한다.
    @State private var selectedCategory: EntryCategory?
    @State private var showCustomForm = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            pickerContent
            recordBottomBar
        }
        .background(AppColors.bg)
        .navigationTitle("카테고리 선택")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCustomForm) {
            CustomCategoryFormView(parentId: selectedMain?.id) { newCategory in
                selectedCategory = newCategory
            }
        }
    }

    private var pickerContent: some View {
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
    }

    /// 하단 고정 CTA: 선택한 카테고리로 기록 시작. 선택 상태는 chip의 선택 링으로만 표시한다.
    private var recordBottomBar: some View {
        PrimaryButton(
            title: selectedCategory.map { "\($0.name)(으)로 기록하기" } ?? "기록하기",
            isEnabled: selectedCategory != nil
        ) {
            if let selectedCategory {
                openEditor(with: selectedCategory)
            }
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.vertical, AppLayout.mediumGap)
        .background(AppColors.surface)
        .overlay(alignment: .top) {
            Divider().overlay(AppColors.line)
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
                        selectedCategory = category
                    } label: {
                        CategoryChip(category: category, isSelected: selectedCategory?.id == category.id)
                    }
                }
            }
        }
    }

    private var mainCategoryGrid: some View {
        LazyVGrid(columns: columns, spacing: AppLayout.mediumGap) {
            ForEach(categoryRepository.mainCategories) { category in
                Button {
                    withAnimation {
                        selectedMain = category
                        selectedCategory = category
                    }
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
                    withAnimation {
                        selectedMain = nil
                        selectedCategory = nil
                    }
                } label: {
                    Label("전체 카테고리", systemImage: "chevron.left")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.primary)
                }
                Spacer()
            }

            // 메인 카테고리 자체도 선택 가능
            Button {
                selectedCategory = main
            } label: {
                CategoryChip(category: main, isSelected: selectedCategory?.id == main.id)
            }

            Text("세부 카테고리를 고르면 더 정확하게 모아볼 수 있어요.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textMuted)

            let subs = categoryRepository.subcategories(of: main)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(subs) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        CategoryChip(category: category, isSelected: selectedCategory?.id == category.id)
                    }
                }
            }
        }
    }

    private func openEditor(with category: EntryCategory) {
        router.push(.entryEditor(date: date, categoryId: category.id, entryId: nil))
    }
}
