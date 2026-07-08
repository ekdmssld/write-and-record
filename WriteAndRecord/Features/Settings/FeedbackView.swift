import SwiftUI

enum FeedbackConfig {
    /// 피드백 수신 메일. 배포 전 전용 주소로 교체 권장 (docs/13 1장).
    static let recipient = "ekdms8652@pusan.ac.kr"
}

/// 인앱 피드백 폼 (docs/13 1장 플로우).
/// 유형/내용을 입력받아 진단 정보와 함께 메일 앱으로 보낸다.
/// 메일 앱이 없으면 공유 시트로 fallback.
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    enum FeedbackCategory: String, CaseIterable, Identifiable {
        case bug = "버그"
        case request = "요청"
        case confusing = "헷갈림"
        case other = "기타"

        var id: String { rawValue }
    }

    @State private var category: FeedbackCategory = .bug
    @State private var message = ""
    @State private var includeDiagnostics = true
    @State private var showShareFallback = false
    @State private var toastMessage: String?

    /// 진단 정보. 기록 본문/제목 등 민감 데이터는 절대 포함하지 않는다 (docs/05 15장).
    private var diagnostics: String {
        let device = UIDevice.current
        return """
        ---
        App: Write & Record \(BuildConfiguration.appVersionString)
        Mode: \(BuildConfiguration.current.rawValue)
        iOS: \(device.systemVersion)
        Device: \(device.model)
        유형: \(category.rawValue)
        ---
        """
    }

    private var fullBody: String {
        includeDiagnostics ? "\(message)\n\n\(diagnostics)" : message
    }

    private var canSend: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppLayout.largeGap) {
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("어떤 피드백인가요?")
                            .font(AppTypography.headline)
                        Picker("피드백 유형", selection: $category) {
                            ForEach(FeedbackCategory.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("내용")
                            .font(AppTypography.headline)
                        TextEditor(text: $message)
                            .font(AppTypography.body)
                            .frame(minHeight: 120)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                                    .stroke(AppColors.line, lineWidth: 1)
                            )
                        Text("무엇을 하려고 했고, 무엇이 예상과 달랐는지 적어주시면 큰 도움이 돼요.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }

                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Toggle("진단 정보 포함", isOn: $includeDiagnostics)
                            .font(AppTypography.body)
                        if includeDiagnostics {
                            Text(diagnostics)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(AppColors.textMuted)
                                .padding(AppLayout.smallGap)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.surfaceAlt)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                            Text("기록 내용이나 사진은 포함되지 않아요.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }

                    VStack(spacing: AppLayout.smallGap) {
                        PrimaryButton(title: "메일로 보내기", isEnabled: canSend) {
                            sendByMail()
                        }
                        Button("메일 앱이 없어요 — 공유하기로 보내기") {
                            showShareFallback = true
                        }
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textMuted)
                        .disabled(!canSend)
                    }
                }
                .padding(AppLayout.horizontalPadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColors.bg)
            .navigationTitle("피드백 보내기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .toast(message: $toastMessage)
            .sheet(isPresented: $showShareFallback) {
                ShareSheet(items: ["[Write & Record 피드백]\n\(fullBody)"])
            }
        }
    }

    private func sendByMail() {
        let subject = "Write & Record 피드백 - \(category.rawValue)"
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedBody = fullBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "mailto:\(FeedbackConfig.recipient)?subject=\(encodedSubject)&body=\(encodedBody)") else {
            toastMessage = "메일을 준비하지 못했어요."
            return
        }
        UIApplication.shared.open(url) { success in
            if !success {
                // 메일 계정이 설정되지 않은 기기: 공유 시트로 fallback
                showShareFallback = true
            }
        }
    }
}
