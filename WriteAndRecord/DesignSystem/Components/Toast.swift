import SwiftUI

/// 저장 성공 등 1.5초 toast (Design Spec 8장).
struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let message {
                Text(message)
                    .font(AppTypography.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                self.message = nil
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

/// 빈 상태 공용 뷰.
struct EmptyStateView: View {
    let iconName: String
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppLayout.mediumGap) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundStyle(AppColors.textMuted)
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.text)
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.primary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, AppLayout.horizontalPadding)
    }
}
