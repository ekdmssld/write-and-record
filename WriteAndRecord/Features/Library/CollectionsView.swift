import SwiftUI

/// 스마트 컬렉션: 위시리스트 / 별점 5 / 최근 30일 / 카테고리별.
/// 수동 컬렉션은 P2에서 확장.
struct CollectionsView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                smartCollectionRow(
                    icon: "bookmark.fill",
                    title: "위시리스트",
                    entries: entryRepository.wishlistEntries
                )
                smartCollectionRow(
                    icon: "star.fill",
                    title: "별점 5",
                    entries: entryRepository.fiveStarEntries
                )
                smartCollectionRow(
                    icon: "clock.fill",
                    title: "최근 30일",
                    entries: entryRepository.recentEntries
                )

                Text("카테고리별")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.top, AppLayout.smallGap)

                ForEach(categoryRepository.mainCategories) { category in
                    let entries = entryRepository.entriesByDateDescending().filter {
                        $0.categoryId == category.id
                            || categoryRepository.category(id: $0.categoryId)?.parentId == category.id
                    }
                    if !entries.isEmpty {
                        smartCollectionRow(icon: category.icon, title: category.name, entries: entries, colorHex: category.colorHex)
                    }
                }

                if entryRepository.activeEntries.isEmpty {
                    EmptyStateView(
                        iconName: "square.stack",
                        title: "아직 컬렉션이 비어 있어요",
                        subtitle: "기록이 쌓이면 자동으로 모아드려요."
                    )
                }
            }
            .padding(.vertical, AppLayout.smallGap)
        }
    }

    @ViewBuilder
    private func smartCollectionRow(icon: String, title: String, entries: [Entry], colorHex: String = "#A16879") -> some View {
        if !entries.isEmpty {
            NavigationLink {
                CollectionEntriesView(title: title, entries: entries)
            } label: {
                HStack(spacing: AppLayout.mediumGap) {
                    Image(systemName: icon)
                        .foregroundStyle(AppColors.category(colorHex))
                        .frame(width: 32)
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.text)
                    Spacer()
                    Text("\(entries.count)")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textMuted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textMuted)
                }
                .padding(AppLayout.mediumGap)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                        .stroke(AppColors.line, lineWidth: 1)
                )
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .accessibilityLabel("\(title) 컬렉션, 기록 \(entries.count)개")
        }
    }
}

struct CollectionEntriesView: View {
    let title: String
    let entries: [Entry]

    @EnvironmentObject private var router: NavigationRouter

    var body: some View {
        ScrollView {
            VStack(spacing: AppLayout.smallGap) {
                ForEach(entries) { entry in
                    Button {
                        router.push(.entryDetail(entryId: entry.id))
                    } label: {
                        EntryCardView(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.mediumGap)
        }
        .background(AppColors.bg)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
