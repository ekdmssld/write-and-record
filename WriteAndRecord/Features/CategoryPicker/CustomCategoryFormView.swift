import SwiftUI

/// 커스텀 카테고리 생성 폼: 이름, 아이콘, 색상, 부모 카테고리 optional.
struct CustomCategoryFormView: View {
    var parentId: String?
    var onCreated: ((EntryCategory) -> Void)?

    @EnvironmentObject private var categoryRepository: CategoryRepository
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "tag"
    @State private var selectedColorHex = "#9A9A9A"
    @State private var selectedParentId: String?
    @State private var errorMessage: String?

    private let iconOptions = [
        "tag", "heart", "star", "flame", "leaf", "gamecontroller",
        "paintbrush", "camera", "cart", "gift", "pawprint", "airplane",
        "cup.and.saucer", "graduationcap", "briefcase", "moon.stars"
    ]

    private let colorOptions = [
        "#F4A7B9", "#F2A65A", "#B794F4", "#59B88D",
        "#6AA9FF", "#B68B5E", "#FF7AA2", "#50B9B0",
        "#9A9A9A", "#5B6CFF", "#D94A4A", "#2E8B57"
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
            .navigationTitle("커스텀 카테고리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("만들기") { create() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                selectedParentId = parentId
            }
        }
    }

    private func create() {
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
