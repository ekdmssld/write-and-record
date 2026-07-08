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
                wishlistRow
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
                quoteRow

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

    /// 위시리스트는 분류(보고/읽고/가고 싶은...)별 그룹 뷰로 이동한다.
    @ViewBuilder
    private var wishlistRow: some View {
        let entries = entryRepository.wishlistEntries
        if !entries.isEmpty {
            NavigationLink {
                WishlistCollectionView(entries: entries)
            } label: {
                HStack(spacing: AppLayout.mediumGap) {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 32)
                    Text("위시리스트")
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
            .accessibilityLabel("위시리스트 컬렉션, 기록 \(entries.count)개")
        }
    }

    /// 인용구가 있는 기록 모음 — 문장 중심 카드 뷰로 이동.
    @ViewBuilder
    private var quoteRow: some View {
        let entries = entryRepository.quoteEntries
        if !entries.isEmpty {
            NavigationLink {
                QuoteCollectionView(entries: entries)
            } label: {
                HStack(spacing: AppLayout.mediumGap) {
                    Image(systemName: "quote.opening")
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 32)
                    Text("인용구")
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
            .accessibilityLabel("인용구 컬렉션, \(entries.count)개")
        }
    }

    @ViewBuilder
    private func smartCollectionRow(icon: String, title: String, entries: [Entry], colorHex: String = "#A4565C") -> some View {
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

/// 위시리스트를 분류별로 묶어 보여준다 (docs/12 J).
struct WishlistCollectionView: View {
    let entries: [Entry]

    @EnvironmentObject private var router: NavigationRouter

    private var grouped: [(type: WishlistType?, entries: [Entry])] {
        var result: [(WishlistType?, [Entry])] = []
        for type in WishlistType.allCases {
            let matching = entries.filter { $0.wishlistType == type }
            if !matching.isEmpty {
                result.append((type, matching))
            }
        }
        let untyped = entries.filter { $0.wishlistType == nil }
        if !untyped.isEmpty {
            result.append((nil, untyped))
        }
        return result.map { (type: $0.0, entries: $0.1) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Label(
                            group.type?.displayName ?? "분류 없음",
                            systemImage: group.type?.iconName ?? "bookmark"
                        )
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.text)
                        .padding(.horizontal, AppLayout.horizontalPadding)

                        ForEach(group.entries) { entry in
                            Button {
                                router.push(.entryDetail(entryId: entry.id))
                            } label: {
                                EntryCardView(entry: entry)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, AppLayout.horizontalPadding)
                        }
                    }
                }
            }
            .padding(.vertical, AppLayout.mediumGap)
        }
        .background(AppColors.bg)
        .navigationTitle("위시리스트")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 저장한 인용구/문장을 문장 중심 카드로 보여준다 (docs/12 E).
struct QuoteCollectionView: View {
    let entries: [Entry]

    @EnvironmentObject private var categoryRepository: CategoryRepository
    @EnvironmentObject private var router: NavigationRouter

    var body: some View {
        ScrollView {
            VStack(spacing: AppLayout.mediumGap) {
                ForEach(entries) { entry in
                    if let quote = entry.quoteText {
                        Button {
                            router.push(.entryDetail(entryId: entry.id))
                        } label: {
                            quoteCard(entry: entry, quote: quote)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.mediumGap)
        }
        .background(AppColors.bg)
        .navigationTitle("인용구")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func quoteCard(entry: Entry, quote: String) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.smallGap) {
            Image(systemName: "quote.opening")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.category(categoryRepository.colorHex(forEntry: entry)))
            Text(quote)
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.text)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            HStack(spacing: 6) {
                Circle()
                    .fill(AppColors.category(categoryRepository.colorHex(forEntry: entry)))
                    .frame(width: 7, height: 7)
                Text(entry.title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .lineLimit(1)
                Text(DateUtils.short(entry.date))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.largeGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
        .accessibilityLabel("인용구: \(quote), \(entry.title)")
    }
}
