import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColors.primary)
                .foregroundStyle(AppColors.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                .opacity(isEnabled ? 1 : 0.35)
        }
        .disabled(!isEnabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.surfaceAlt)
                .foregroundStyle(AppColors.text)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.buttonRadius)
                        .stroke(AppColors.line, lineWidth: 1)
                )
        }
    }
}

struct IconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 44, height: 44)
                .foregroundStyle(AppColors.text)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}
