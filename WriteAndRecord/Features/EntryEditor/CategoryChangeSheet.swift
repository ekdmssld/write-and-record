import SwiftUI

/// 에디터 작성 중 카테고리 변경 시트.
/// 메인 카테고리를 펼쳐 세부 카테고리까지 고를 수 있다.
struct CategoryChangeSheet: View {
    let currentCategoryId: String
    let onSelect: (EntryCategory) -> Void

    @EnvironmentObject private var categoryRepository: CategoryRepository
    @Environment(\.dismiss) private var dismiss

    @State private var expandedMainId: String?

    var body: some View {
        NavigationStack {
            List {
                ForEach(categoryRepository.mainCategories) { main in
                    Section {
                        categoryRow(main)
                        if expandedMainId == main.id {
                            ForEach(categoryRepository.subcategories(of: main)) { sub in
                                categoryRow(sub, indented: true)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.bg)
            .navigationTitle("카테고리 변경")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .onAppear {
                // 현재 카테고리가 세부라면 해당 메인을 펼친 상태로 시작
                if let current = categoryRepository.category(id: currentCategoryId) {
                    expandedMainId = current.parentId ?? current.id
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func categoryRow(_ category: EntryCategory, indented: Bool = false) -> some View {
        HStack(spacing: AppLayout.smallGap) {
            if indented {
                Spacer().frame(width: 20)
            }
            Image(systemName: category.icon)
                .foregroundStyle(AppColors.category(category.colorHex))
                .frame(width: 24)
            Text(category.name)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.text)
            Spacer()
            if category.id == currentCategoryId {
                Image(systemName: "checkmark")
                    .foregroundStyle(AppColors.primary)
            } else if !indented && !categoryRepository.subcategories(of: category).isEmpty {
                Image(systemName: expandedMainId == category.id ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !indented && !categoryRepository.subcategories(of: category).isEmpty && expandedMainId != category.id {
                // 첫 탭: 세부 카테고리 펼치기
                withAnimation { expandedMainId = category.id }
            } else {
                onSelect(category)
                dismiss()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.name)\(category.id == currentCategoryId ? ", 현재 선택됨" : "")")
    }
}
