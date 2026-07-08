import SwiftUI

/// 기록 공개 범위 bottom sheet (docs/11 8장).
/// 전체 공개로 바꿀 때는 한 번 더 확인한다.
struct VisibilityPickerSheet: View {
    let current: EntryVisibility
    let onSelect: (EntryVisibility) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pendingPublic = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
            Text("공개 범위")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.text)
                .padding(.top, AppLayout.largeGap)

            ForEach(EntryVisibility.allCases) { option in
                Button {
                    if option == .publicAll && current != .publicAll {
                        pendingPublic = true
                    } else {
                        onSelect(option)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: AppLayout.mediumGap) {
                        Image(systemName: option.iconName)
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.displayName)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.text)
                            Text(option.explanation)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }
                        Spacer()
                        if option == current {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                    .padding(AppLayout.mediumGap)
                    .background(option == current ? AppColors.primary.opacity(0.08) : AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                            .stroke(option == current ? AppColors.primary : AppColors.line, lineWidth: 1)
                    )
                }
                .accessibilityLabel("\(option.displayName), \(option.explanation)\(option == current ? ", 선택됨" : "")")
            }

            Spacer()
        }
        .padding(.horizontal, AppLayout.horizontalPadding)
        .background(AppColors.bg)
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
        .alert("전체 공개로 바꿀까요?", isPresented: $pendingPublic) {
            Button("전체 공개") {
                onSelect(.publicAll)
                dismiss()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("이 기록은 공개 사용자에게 보일 수 있어요.")
        }
    }
}
