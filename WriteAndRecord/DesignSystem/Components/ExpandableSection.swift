import SwiftUI

/// 에디터 추가 섹션용 접힘/확장 카드.
/// 접힌 상태에서는 제목 + 내용 요약만 보여주고, 탭하면 입력 영역이 펼쳐진다.
struct ExpandableSection<Content: View>: View {
    let title: String
    let systemImage: String
    /// 접힌 상태에서 보여줄 요약 (예: "2개", 입력값 미리보기). 없으면 생략.
    var summary: String?
    @ViewBuilder let content: Content

    @State private var isExpanded: Bool

    init(
        title: String,
        systemImage: String,
        summary: String? = nil,
        initiallyExpanded: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.summary = summary
        self.content = content()
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppLayout.smallGap) {
                    Image(systemName: systemImage)
                        .foregroundStyle(AppColors.textMuted)
                        .frame(width: 24)
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.text)
                    if let summary, !isExpanded {
                        Text(summary)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.primary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(AppLayout.mediumGap)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) 섹션, \(isExpanded ? "펼쳐짐" : "접힘")")

            if isExpanded {
                content
                    .padding(.horizontal, AppLayout.mediumGap)
                    .padding(.bottom, AppLayout.mediumGap)
            }
        }
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }
}

/// 글 길이에 맞게 자라는 멀티라인 입력 필드.
struct GrowingTextField: View {
    let placeholder: String
    @Binding var text: String
    var lineRange: ClosedRange<Int> = 1...5

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .font(AppTypography.body)
            .lineLimit(lineRange)
            .padding(10)
            .background(AppColors.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
    }
}
