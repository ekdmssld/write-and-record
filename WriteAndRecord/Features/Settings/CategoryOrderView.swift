import SwiftUI

struct CategoryOrderView: View {
    @EnvironmentObject private var categoryRepository: CategoryRepository

    var body: some View {
        List {
            Section {
                ForEach(categoryRepository.mainCategories) { category in
                    CategoryOrderRow(category: category)
                }
                .onMove { offsets, destination in
                    categoryRepository.moveCategories(parentId: nil, fromOffsets: offsets, toOffset: destination)
                }
            } header: {
                Text("메인 카테고리")
            } footer: {
                Text("오른쪽 편집 버튼을 누른 뒤 끌어서 기록 화면에 보이는 순서를 바꿀 수 있어요.")
            }

            ForEach(categoryRepository.mainCategories) { mainCategory in
                let subcategories = categoryRepository.subcategories(of: mainCategory)
                if !subcategories.isEmpty {
                    Section("\(mainCategory.name) 세부 카테고리") {
                        ForEach(subcategories) { category in
                            CategoryOrderRow(category: category)
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
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.bg)
        .navigationTitle("카테고리 순서")
        .toolbar {
            EditButton()
        }
    }
}

private struct CategoryOrderRow: View {
    let category: EntryCategory

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

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.vertical, 4)
        .accessibilityLabel("\(category.name) 순서 변경")
    }
}
