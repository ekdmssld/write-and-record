import SwiftUI

/// 최신순 타임라인. 월/연도 sticky header + 카테고리/별점/위시 필터.
struct TimelineView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var filterCategoryId: String?
    @State private var wishlistOnly = false
    @State private var fiveStarOnly = false

    private var filteredEntries: [Entry] {
        entryRepository.entriesByDateDescending().filter { entry in
            if let filterCategoryId {
                let matches = entry.categoryId == filterCategoryId
                    || categoryRepository.category(id: entry.categoryId)?.parentId == filterCategoryId
                if !matches { return false }
            }
            if wishlistOnly && !entry.isWishlist { return false }
            if fiveStarOnly && entry.rating != 5 { return false }
            return true
        }
    }

    private var groupedByMonth: [(month: String, entries: [Entry])] {
        var groups: [(String, [Entry])] = []
        for entry in filteredEntries {
            let key = DateUtils.monthTitle(entry.date)
            if let lastIndex = groups.indices.last, groups[lastIndex].0 == key {
                groups[lastIndex].1.append(entry)
            } else {
                groups.append((key, [entry]))
            }
        }
        return groups.map { (month: $0.0, entries: $0.1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            if filteredEntries.isEmpty {
                ScrollView {
                    EmptyStateView(
                        iconName: "clock",
                        title: "표시할 기록이 없어요",
                        subtitle: wishlistOnly || fiveStarOnly || filterCategoryId != nil
                            ? "필터를 바꿔보세요."
                            : "첫 기록을 남겨볼까요?"
                    )
                }
            } else {
                List {
                    ForEach(groupedByMonth, id: \.month) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                Button {
                                    router.push(.entryDetail(entryId: entry.id))
                                } label: {
                                    EntryCardView(entry: entry)
                                }
                                .buttonStyle(.plain)
                                .listRowSeparator(.hidden)
                                .listRowBackground(AppColors.bg)
                                .listRowInsets(EdgeInsets(
                                    top: 4, leading: AppLayout.horizontalPadding,
                                    bottom: 4, trailing: AppLayout.horizontalPadding
                                ))
                            }
                        } header: {
                            Text(group.month)
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColors.text)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppLayout.smallGap) {
                filterChip(title: "위시", isOn: wishlistOnly) { wishlistOnly.toggle() }
                filterChip(title: "별점 5", isOn: fiveStarOnly) { fiveStarOnly.toggle() }
                ForEach(categoryRepository.mainCategories) { category in
                    filterChip(title: category.name, isOn: filterCategoryId == category.id) {
                        filterCategoryId = filterCategoryId == category.id ? nil : category.id
                    }
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.smallGap)
        }
    }

    private func filterChip(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isOn ? AppColors.primary.opacity(0.12) : AppColors.surfaceAlt)
                .foregroundStyle(isOn ? AppColors.primary : AppColors.textMuted)
                .clipShape(Capsule())
        }
        .accessibilityLabel("\(title) 필터\(isOn ? ", 켜짐" : "")")
    }
}
