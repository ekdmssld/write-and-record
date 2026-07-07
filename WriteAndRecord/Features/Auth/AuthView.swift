import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppLayout.mediumGap) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.primary)
                Text("Write & Record")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColors.text)
                Text("하루를 고르고, 좋아한 것을 기록해요.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()

            VStack(spacing: AppLayout.mediumGap) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.danger)
                        .multilineTextAlignment(.center)
                }

                Button {
                    signIn(.apple)
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Apple로 계속하기")
                            .font(AppTypography.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                }
                .disabled(isLoading)

                SecondaryButton(title: "이메일로 계속하기") {
                    signIn(.email)
                }
                .disabled(isLoading)

                if FeatureFlags.enableMockAuth {
                    Button("개발용 mock 로그인") {
                        signIn(.mock)
                    }
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.textMuted)
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.bottom, AppLayout.largeGap)
        }
        .background(AppColors.bg)
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    private func signIn(_ provider: AuthProvider) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await appState.signIn(provider: provider)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
