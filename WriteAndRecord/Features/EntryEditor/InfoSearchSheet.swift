import SwiftUI

/// 에디터의 "정보 검색" 시트 (docs/12 A).
/// 영화/책/음악을 검색해 선택하면 제목과 카테고리 상세 필드를 채운다.
struct InfoSearchSheet: View {
    let kind: ExternalSearchKind
    let onSelect: (ExternalSearchResult) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [ExternalSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: AppLayout.smallGap) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.textMuted)
                    TextField("\(kind.displayName) 제목 검색", text: $query)
                        .font(AppTypography.body)
                        .submitLabel(.search)
                        .onSubmit { runSearch() }
                    if isSearching {
                        ProgressView()
                    }
                }
                .padding(12)
                .background(AppColors.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius))
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.vertical, AppLayout.smallGap)

                content
            }
            .background(AppColors.bg)
            .navigationTitle("\(kind.displayName) 정보 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .onChange(of: query) { _, _ in
                // 0.4초 debounce 자동 검색
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    guard !Task.isCancelled else { return }
                    await performSearch()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let errorMessage {
            EmptyStateView(
                iconName: "wifi.exclamationmark",
                title: "검색하지 못했어요",
                subtitle: errorMessage,
                actionTitle: "다시 시도"
            ) {
                runSearch()
            }
            .frame(maxHeight: .infinity)
        } else if results.isEmpty {
            EmptyStateView(
                iconName: "magnifyingglass",
                title: query.trimmingCharacters(in: .whitespaces).isEmpty
                    ? "제목으로 검색해 보세요"
                    : (isSearching ? "검색 중이에요" : "검색 결과가 없어요"),
                subtitle: "찾는 결과가 없어도 직접 입력할 수 있어요."
            )
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: AppLayout.smallGap) {
                    ForEach(results) { result in
                        Button {
                            onSelect(result)
                            dismiss()
                        } label: {
                            resultRow(result)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.vertical, AppLayout.smallGap)
            }
        }
    }

    private func resultRow(_ result: ExternalSearchResult) -> some View {
        HStack(spacing: AppLayout.mediumGap) {
            AsyncImage(url: result.artworkUrl) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    ZStack {
                        AppColors.surfaceAlt
                        Image(systemName: "photo")
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                    .lineLimit(2)
                Text(result.creator)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "plus.circle")
                .foregroundStyle(AppColors.primary)
        }
        .padding(AppLayout.smallGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
        .accessibilityLabel("\(result.title), \(result.creator), 선택하면 기록에 채워져요")
    }

    private func runSearch() {
        searchTask?.cancel()
        searchTask = Task {
            await performSearch()
        }
    }

    @MainActor
    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            return
        }
        isSearching = true
        errorMessage = nil
        do {
            let found = try await ExternalSearchService.search(trimmed, kind: kind)
            if !Task.isCancelled {
                results = found
            }
        } catch is CancellationError {
            // 새 검색으로 대체됨
        } catch {
            errorMessage = "네트워크 연결을 확인해 주세요."
        }
        isSearching = false
    }
}
