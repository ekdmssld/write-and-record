import SwiftUI

/// 장소별 기록 목록 (MVP는 리스트, 지도는 P2).
struct PlacesView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var showNoPlace = false

    private var placedEntries: [Entry] {
        entryRepository.entriesByDateDescending().filter { $0.place != nil }
    }

    private var noPlaceEntries: [Entry] {
        entryRepository.entriesByDateDescending().filter { $0.place == nil }
    }

    private var groupedByPlace: [(place: String, entries: [Entry])] {
        var groups: [String: [Entry]] = [:]
        for entry in placedEntries {
            let name = entry.place?.name ?? ""
            groups[name, default: []].append(entry)
        }
        return groups
            .map { (place: $0.key, entries: $0.value) }
            .sorted { $0.place < $1.place }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                Toggle("장소 없는 기록 표시", isOn: $showNoPlace)
                    .font(AppTypography.callout)
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.top, AppLayout.smallGap)

                if placedEntries.isEmpty && !showNoPlace {
                    EmptyStateView(
                        iconName: "mappin.and.ellipse",
                        title: "장소가 있는 기록이 없어요",
                        subtitle: "기록에 장소를 추가하면 여기에 모여요."
                    )
                }

                ForEach(groupedByPlace, id: \.place) { group in
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Label(group.place, systemImage: "mappin.and.ellipse")
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

                if showNoPlace && !noPlaceEntries.isEmpty {
                    VStack(alignment: .leading, spacing: AppLayout.smallGap) {
                        Text("장소 없음")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textMuted)
                            .padding(.horizontal, AppLayout.horizontalPadding)
                        ForEach(noPlaceEntries) { entry in
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
            .padding(.bottom, AppLayout.largeGap)
        }
    }
}
