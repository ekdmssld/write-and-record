import SwiftUI

struct CategoryChip: View {
    let category: EntryCategory
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.system(size: 13, weight: .medium))
            Text(category.name)
                .font(AppTypography.callout)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.category(category.colorHex).opacity(0.15))
        .foregroundStyle(AppColors.text)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(isSelected ? AppColors.primary : .clear, lineWidth: 2)
        )
        .accessibilityLabel("카테고리 \(category.name)\(isSelected ? ", 선택됨" : "")")
    }
}
