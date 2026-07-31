import SwiftUI

/// 내가 공유한 기록 모아보기 (docs/10 11장: "내 public 기록 한 번에 보기").
/// 친구 공개/전체 공개로 설정한 기록을 한 곳에서 확인하고 되돌릴 수 있게 한다.
struct MySharedEntriesView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var router: NavigationRouter

    private var sharedEntries: [Entry] {
        entryRepository.activeEntries
            .filter { $0.effectiveVisibility != .privateOnly }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if sharedEntries.isEmpty {
                EmptyStateView(
                    iconName: "square.and.arrow.up",
                    title: "공유한 기록이 없어요",
                    subtitle: "기록을 저장할 때 공개 범위를 '친구에게 공개'나 '전체 공개'로 바꾸면 여기 모여요."
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: AppLayout.smallGap) {
                        ForEach(sharedEntries) { entry in
                            Button {
                                router.push(.entryDetail(entryId: entry.id))
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    EntryCardView(entry: entry)
                                    Label(entry.effectiveVisibility.displayName, systemImage: entry.effectiveVisibility.iconName)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.textMuted)
                                        .padding(.horizontal, 4)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(AppLayout.horizontalPadding)
                }
            }
        }
        .background(AppColors.bg)
        .navigationTitle("내가 공유한 기록")
        .navigationBarTitleDisplayMode(.inline)
    }
}
