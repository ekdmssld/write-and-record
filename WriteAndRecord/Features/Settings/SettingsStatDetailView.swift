import SwiftUI

enum SettingsStatKind {
    case allEntries
    case wishlist
    case fiveStar
    case recordCards

    var title: String {
        switch self {
        case .allEntries: return "전체 기록"
        case .wishlist: return "위시리스트"
        case .fiveStar: return "별점 5 기록"
        case .recordCards: return "만든 기록 카드"
        }
    }

    var iconName: String {
        switch self {
        case .allEntries: return "square.and.pencil"
        case .wishlist: return "bookmark.fill"
        case .fiveStar: return "star.fill"
        case .recordCards: return "rectangle.on.rectangle"
        }
    }

    var colorHex: String {
        switch self {
        case .allEntries: return "#818263"
        case .wishlist: return "#DDBAAE"
        case .fiveStar: return "#EFD7CF"
        case .recordCards: return "#A4AAAA"
        }
    }

    var emptyTitle: String {
        switch self {
        case .allEntries: return "아직 기록이 없어요"
        case .wishlist: return "위시리스트 기록이 없어요"
        case .fiveStar: return "별점 5 기록이 없어요"
        case .recordCards: return "아직 만든 기록 카드가 없어요"
        }
    }

    var emptySubtitle: String {
        switch self {
        case .allEntries: return "기록 탭에서 오늘의 기록을 남겨보세요."
        case .wishlist: return "기억해두고 싶은 것을 위시로 표시하면 여기 모여요."
        case .fiveStar: return "정말 좋았던 기록에 별점 5를 남기면 여기서 바로 볼 수 있어요."
        case .recordCards: return "기록 상세에서 카드 만들기를 하면 생성 이력이 여기에 쌓여요."
        }
    }
}

struct SettingsStatDetailView: View {
    let kind: SettingsStatKind

    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var router: NavigationRouter

    private var entries: [Entry] {
        switch kind {
        case .allEntries:
            return entryRepository.entriesByDateDescending()
        case .wishlist:
            return entryRepository.wishlistEntries
        case .fiveStar:
            return entryRepository.fiveStarEntries
        case .recordCards:
            return []
        }
    }

    private var cards: [RecordCard] {
        entryRepository.recordCards.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            if kind == .recordCards {
                recordCardContent
            } else {
                entryContent
            }
        }
        .background(AppColors.bg)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var entryContent: some View {
        if entries.isEmpty {
            EmptyStateView(
                iconName: kind.iconName,
                title: kind.emptyTitle,
                subtitle: kind.emptySubtitle
            )
            .padding(.top, AppLayout.largeGap)
        } else {
            VStack(spacing: AppLayout.smallGap) {
                ForEach(entries) { entry in
                    Button {
                        router.push(.entryDetail(entryId: entry.id))
                    } label: {
                        EntryCardView(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(entry.title) 기록 보기")
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.mediumGap)
        }
    }

    @ViewBuilder
    private var recordCardContent: some View {
        if cards.isEmpty {
            EmptyStateView(
                iconName: kind.iconName,
                title: kind.emptyTitle,
                subtitle: kind.emptySubtitle
            )
            .padding(.top, AppLayout.largeGap)
        } else {
            VStack(spacing: AppLayout.smallGap) {
                ForEach(cards) { card in
                    if let entry = entryRepository.entry(id: card.entryId) {
                        Button {
                            router.push(.entryDetail(entryId: entry.id))
                        } label: {
                            SettingsRecordCardRow(card: card, entry: entry)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(entry.title) 기록 카드 보기")
                    } else {
                        SettingsRecordCardRow(card: card, entry: nil)
                    }
                }
            }
            .padding(.horizontal, AppLayout.horizontalPadding)
            .padding(.vertical, AppLayout.mediumGap)
        }
    }
}

private struct SettingsRecordCardRow: View {
    let card: RecordCard
    let entry: Entry?

    private var template: RecordCardTemplate? {
        RecordCardTemplate(rawValue: card.templateId)
    }

    var body: some View {
        HStack(spacing: AppLayout.mediumGap) {
            ZStack {
                RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                    .fill(AppColors.category("#A4AAAA").opacity(0.16))
                Image(systemName: template?.iconName ?? "rectangle.on.rectangle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColors.category("#A4AAAA"))
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(template?.displayName ?? "기록 카드")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)

                Text(entry?.title ?? "삭제된 기록")
                    .font(AppTypography.callout)
                    .foregroundStyle(entry == nil ? AppColors.textMuted : AppColors.text)
                    .lineLimit(1)

                Text("\(DateUtils.short(card.createdAt))에 만들었어요")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer(minLength: 0)

            if entry != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .padding(AppLayout.mediumGap)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius)
                .stroke(AppColors.line, lineWidth: 1)
        )
    }
}
