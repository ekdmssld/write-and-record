import SwiftUI
import MapKit

/// 장소별 기록 목록. 좌표가 있는 장소는 지도 핀으로도 표시한다.
struct PlacesView: View {
    @EnvironmentObject private var entryRepository: EntryRepository
    @EnvironmentObject private var router: NavigationRouter

    @State private var showNoPlace = false
    @State private var displayMode: PlacesDisplayMode = .list

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

    private var mappedMarkers: [PlaceMapMarker] {
        var groups: [String: [Entry]] = [:]
        for entry in placedEntries {
            guard let key = mapGroupKey(for: entry) else { continue }
            groups[key, default: []].append(entry)
        }

        return groups.compactMap { key, entries in
            guard let firstEntry = entries.first,
                  let place = firstEntry.place,
                  let latitude = place.latitude,
                  let longitude = place.longitude else { return nil }

            let photoCount = entries.reduce(0) { total, entry in
                total + entry.assetIds.count
            }
            let badgeCount = max(photoCount, entries.count)
            let subtitle = entries.count > 1 ? "\(entries.count)개 기록" : place.address

            return PlaceMapMarker(
                id: key,
                primaryEntryId: firstEntry.id,
                title: place.name,
                subtitle: subtitle,
                coordinate: .init(latitude: latitude, longitude: longitude),
                coverAsset: entries.compactMap { entryRepository.coverAsset(for: $0) }.first,
                badgeCount: badgeCount
            )
        }
        .sorted { $0.title < $1.title }
    }

    var body: some View {
        VStack(spacing: 0) {
            modeSwitch

            switch displayMode {
            case .list:
                listContent
            case .map:
                mapContent
            }
        }
    }

    private var modeSwitch: some View {
        Picker("장소 보기 방식", selection: $displayMode) {
            ForEach(PlacesDisplayMode.allCases) { mode in
                Label(mode.title, systemImage: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AppLayout.horizontalPadding)
        .padding(.top, AppLayout.smallGap)
        .padding(.bottom, AppLayout.smallGap)
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppLayout.mediumGap) {
                Toggle("장소 없는 기록 표시", isOn: $showNoPlace)
                    .font(AppTypography.callout)
                    .padding(.horizontal, AppLayout.horizontalPadding)

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

    @ViewBuilder
    private var mapContent: some View {
        ZStack(alignment: mappedMarkers.isEmpty ? .center : .bottomLeading) {
            PlaceMapView(
                markers: mappedMarkers,
                pinStyle: .photo
            ) { marker in
                if !mappedMarkers.isEmpty {
                    router.push(.entryDetail(entryId: marker.primaryEntryId))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if mappedMarkers.isEmpty {
                VStack(spacing: AppLayout.smallGap) {
                    Image(systemName: "map")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(AppColors.textMuted)
                    Text(placedEntries.isEmpty ? "장소가 있는 기록이 없어요" : "지도에 표시할 좌표가 없어요")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.text)
                    Text(placedEntries.isEmpty
                         ? "기록에 장소를 추가하면 한국 지도 위에 모아볼 수 있어요."
                         : "좌표가 있는 장소 기록이 생기면 사진 핀이 지도에 표시돼요.")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(AppLayout.mediumGap)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                .padding(.horizontal, AppLayout.horizontalPadding)
            } else {
                HStack(spacing: 6) {
                    Label("한국 지도", systemImage: "map")
                    Text("사진 핀 \(mappedMarkers.count)개")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.text)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.thinMaterial)
                .clipShape(Capsule())
                .padding(AppLayout.horizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func mapGroupKey(for entry: Entry) -> String? {
        guard let place = entry.place,
              let latitude = place.latitude,
              let longitude = place.longitude else { return nil }
        let latitudeKey = Int((latitude * 100_000).rounded())
        let longitudeKey = Int((longitude * 100_000).rounded())
        return "\(place.name)-\(latitudeKey)-\(longitudeKey)"
    }
}

private enum PlacesDisplayMode: String, CaseIterable, Identifiable {
    case list
    case map

    var id: String { rawValue }

    var title: String {
        switch self {
        case .list: return "목록"
        case .map: return "지도"
        }
    }

    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .map: return "map"
        }
    }
}
