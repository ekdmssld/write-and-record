import SwiftUI

/// 카테고리 관리: 순서 변경 + 커스텀 수정/삭제 + 기본 카테고리 숨김/복원.
/// (Functional Spec 7장: 기본은 삭제 불가·숨김 가능, 커스텀은 수정/삭제 가능)
struct CategoryOrderView: View {
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var entryRepository: EntryRepository

    @State private var editingCategory: EntryCategory?
    @State private var deletingCategory: EntryCategory?

    var body: some View {
        List {
            Section {
                ForEach(categoryRepository.mainCategories) { category in
                    categoryRow(category)
                }
                .onMove { offsets, destination in
                    categoryRepository.moveCategories(parentId: nil, fromOffsets: offsets, toOffset: destination)
                }
            } header: {
                Text("메인 카테고리")
            } footer: {
                Text("끌어서 순서를 바꾸고, 왼쪽으로 밀어 숨기거나 수정/삭제할 수 있어요.")
            }

            ForEach(categoryRepository.mainCategories) { mainCategory in
                let subcategories = categoryRepository.subcategories(of: mainCategory)
                if !subcategories.isEmpty {
                    Section("\(mainCategory.name) 세부 카테고리") {
                        ForEach(subcategories) { category in
                            categoryRow(category)
                        }
                        .onMove { offsets, destination in
                            categoryRepository.moveCategories(
                                parentId: mainCategory.id,
                                fromOffsets: offsets,
                                toOffset: destination
                            )
                        }
                    }
                }
            }

            hiddenSection
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.bg)
        .navigationTitle("카테고리 관리")
        .toolbar {
            EditButton()
        }
        .sheet(item: $editingCategory) { category in
            CustomCategoryFormView(editing: category)
        }
        .confirmationDialog(
            "'\(deletingCategory?.name ?? "")' 카테고리를 삭제할까요?",
            isPresented: Binding(
                get: { deletingCategory != nil },
                set: { if !$0 { deletingCategory = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                deleteCustomCategory()
            }
            Button("취소", role: .cancel) {
                deletingCategory = nil
            }
        } message: {
            Text("이 카테고리로 쓴 기록은 카테고리 이름을 간직한 채 그대로 남아요.")
        }
    }

    private func categoryRow(_ category: EntryCategory) -> some View {
        CategoryManageRow(category: category)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if category.isDefault {
                    Button {
                        categoryRepository.setArchived(category, archived: true)
                    } label: {
                        Label("숨기기", systemImage: "eye.slash")
                    }
                    .tint(AppColors.textMuted)
                } else {
                    Button(role: .destructive) {
                        deletingCategory = category
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                    Button {
                        editingCategory = category
                    } label: {
                        Label("수정", systemImage: "pencil")
                    }
                    .tint(AppColors.primary)
                }
            }
    }

    @ViewBuilder
    private var hiddenSection: some View {
        let hidden = categoryRepository.archivedCategories
        if !hidden.isEmpty {
            Section {
                ForEach(hidden) { category in
                    HStack {
                        CategoryManageRow(category: category, dimmed: true)
                        Button("복원") {
                            categoryRepository.setArchived(category, archived: false)
                        }
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.primary)
                        .buttonStyle(.borderless)
                    }
                }
            } header: {
                Text("숨긴 카테고리")
            } footer: {
                Text("숨긴 카테고리는 선택 화면에 보이지 않지만, 기존 기록은 유지돼요.")
            }
        }
    }

    private func deleteCustomCategory() {
        guard let category = deletingCategory else { return }
        // 기록에 이름을 남긴 뒤 archive (Product Spec 5장)
        entryRepository.stampArchivedCategoryName(categoryId: category.id, name: category.name)
        try? categoryRepository.archive(category)
        deletingCategory = nil
    }
}

private struct CategoryManageRow: View {
    let category: EntryCategory
    var dimmed: Bool = false

    var body: some View {
        HStack(spacing: AppLayout.smallGap) {
            ZStack {
                Circle()
                    .fill(AppColors.category(category.colorHex).opacity(0.18))
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.category(category.colorHex))
            }
            .frame(width: 30, height: 30)

            Text(category.name)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.text)

            if !category.isDefault {
                Text("커스텀")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.surfaceAlt)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(dimmed ? 0.55 : 1)
        .accessibilityLabel("\(category.name)\(category.isDefault ? "" : ", 커스텀 카테고리")")
    }
}
