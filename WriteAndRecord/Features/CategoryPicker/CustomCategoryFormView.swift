import SwiftUI

/// 커스텀 카테고리 생성/수정 폼: 이름, 아이콘, 색상, 부모 카테고리 optional.
struct CustomCategoryFormView: View {
    var parentId: String?
    /// 값이 있으면 수정 모드.
    var editing: EntryCategory?
    var onCreated: ((EntryCategory) -> Void)?

    @EnvironmentObject private var categoryRepository: CategoryRepository
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "tag"
    @State private var selectedColorHex = "#818263"
    @State private var selectedParentId: String?
    @State private var errorMessage: String?

    private let iconOptions = [
        "tag", "heart", "star", "flame", "leaf", "gamecontroller",
        "paintbrush", "camera", "cart", "gift", "pawprint", "airplane",
        "cup.and.saucer", "graduationcap", "briefcase", "moon.stars"
    ]

    /// 세이지·린넨 팔레트.
    private let colorOptions = [
        "#818263", "#C2C395", "#DCD4C1", "#F2E6D8",
        "#FAF6F1", "#EADFD6", "#A4AAAA", "#CCC2C1",
        "#EFD7CF", "#F7D8CC", "#DDBAAE", "#F6C7CF"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.largeGap) {
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("이름")
                            .font(AppTypography.headline)
                        TextField("카테고리 이름", text: $name)
                            .font(AppTypography.body)
                            .padding(12)
                            .background(AppColors.surfaceAlt)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.danger)
                        }
                    }

                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("아이콘")
                            .font(AppTypography.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 8) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? AppColors.primary.opacity(0.12) : AppColors.surfaceAlt)
                                        .foregroundStyle(selectedIcon == icon ? AppColors.primary : AppColors.text)
                                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                                }
                                .accessibilityLabel("아이콘 \(icon)\(selectedIcon == icon ? ", 선택됨" : "")")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("색상")
                            .font(AppTypography.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 8) {
                            ForEach(colorOptions, id: \.self) { hex in
                                Button {
                                    selectedColorHex = hex
                                } label: {
                                    Circle()
                                        .fill(AppColors.category(hex))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle().stroke(selectedColorHex == hex ? AppColors.text : .clear, lineWidth: 2)
                                        )
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel("색상 \(hex)\(selectedColorHex == hex ? ", 선택됨" : "")")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("상위 카테고리 (선택)")
                            .font(AppTypography.headline)
                        Picker("상위 카테고리", selection: $selectedParentId) {
                            Text("없음").tag(String?.none)
                            ForEach(categoryRepository.mainCategories) { category in
                                Text(category.name).tag(String?.some(category.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding(AppLayout.horizontalPadding)
            }
            .background(AppColors.bg)
            .navigationTitle(editing == nil ? "커스텀 카테고리" : "카테고리 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "만들기" : "저장") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let editing {
                    name = editing.name
                    selectedIcon = editing.icon
                    selectedColorHex = editing.colorHex
                    selectedParentId = editing.parentId
                } else {
                    selectedParentId = parentId
                }
            }
        }
    }

    private func save() {
        if let editing {
            // 수정: 같은 그룹의 다른 카테고리와 이름 중복만 막는다.
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            let hasDuplicate = categoryRepository.activeCategories.contains {
                $0.id != editing.id && $0.parentId == selectedParentId && $0.name == trimmed
            }
            guard !hasDuplicate else {
                errorMessage = "같은 그룹에 이미 같은 이름의 카테고리가 있어요."
                return
            }
            var updated = editing
            updated.name = trimmed
            updated.icon = selectedIcon
            updated.colorHex = selectedColorHex
            updated.parentId = selectedParentId
            categoryRepository.update(updated)
            dismiss()
            onCreated?(updated)
        } else {
            do {
                let newCategory = try categoryRepository.addCustomCategory(
                    name: name,
                    icon: selectedIcon,
                    colorHex: selectedColorHex,
                    parentId: selectedParentId
                )
                dismiss()
                onCreated?(newCategory)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
