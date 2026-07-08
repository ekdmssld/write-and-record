import SwiftUI
@preconcurrency import MapKit

struct PlaceSearchSheet: View {
    let initialQuery: String
    let onSelect: (PlaceRef) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchModel = PlaceSearchModel()

    var body: some View {
        NavigationStack {
            List {
                if searchModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section {
                        ForEach(PlaceSearchSuggestion.examples, id: \.self) { suggestion in
                            Button {
                                searchModel.query = suggestion
                            } label: {
                                Label(suggestion, systemImage: "location.magnifyingglass")
                            }
                        }
                    } header: {
                        Text("이렇게 검색해보세요")
                    } footer: {
                        Text("지역, 동네, 랜드마크, 매장 이름으로 검색하고 선택하면 지도에 표시할 위치가 함께 저장돼요.")
                    }
                } else if searchModel.completions.isEmpty {
                    Section {
                        if searchModel.isSearching {
                            HStack {
                                ProgressView()
                                Text("검색 중")
                                    .foregroundStyle(AppColors.textMuted)
                            }
                        } else {
                            Text("검색 결과가 없어요")
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                } else {
                    Section("검색 결과") {
                        ForEach(Array(searchModel.completions.enumerated()), id: \.offset) { _, completion in
                            Button {
                                select(completion)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(completion.title)
                                        .font(AppTypography.callout)
                                        .foregroundStyle(AppColors.text)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppColors.textMuted)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                        }
                    }
                }
            }
            .navigationTitle("장소 선택")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "지역, 랜드마크, 주소")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if searchModel.isResolving {
                    ProgressView("장소 확인 중")
                        .padding(AppLayout.mediumGap)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius))
                }
            }
            .onAppear {
                if searchModel.query.isEmpty {
                    searchModel.query = initialQuery
                }
            }
        }
    }

    private func select(_ completion: MKLocalSearchCompletion) {
        Task {
            if let place = await searchModel.resolve(completion) {
                await MainActor.run {
                    onSelect(place)
                    dismiss()
                }
            }
        }
    }
}

private enum PlaceSearchSuggestion {
    static let examples = ["성수동", "롯데월드몰", "국립중앙박물관", "한남동 카페", "부산 해운대"]
}

final class PlaceSearchModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query: String = "" {
        didSet {
            updateQuery()
        }
    }
    @Published private(set) var completions: [MKLocalSearchCompletion] = []
    @Published private(set) var isSearching = false
    @Published private(set) var isResolving = false

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.region = Self.koreaRegion
        completer.resultTypes = [.address, .pointOfInterest, .query]
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completions = completer.results
        isSearching = false
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        completions = []
        isSearching = false
    }

    func resolve(_ completion: MKLocalSearchCompletion) async -> PlaceRef? {
        await MainActor.run {
            isResolving = true
        }

        return await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request(completion: completion)
            request.region = Self.koreaRegion
            MKLocalSearch(request: request).start { [weak self] response, _ in
                DispatchQueue.main.async {
                    self?.isResolving = false
                }

                guard let mapItem = response?.mapItems.first else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: Self.placeRef(from: mapItem, completion: completion))
            }
        }
    }

    private func updateQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completions = []
            isSearching = false
            completer.queryFragment = ""
            return
        }
        isSearching = true
        completer.queryFragment = trimmed
    }

    private static func placeRef(from mapItem: MKMapItem, completion: MKLocalSearchCompletion) -> PlaceRef {
        let placemark = mapItem.placemark
        let coordinate = placemark.coordinate
        let address = addressString(from: placemark, fallback: completion.subtitle)
        return PlaceRef(
            name: mapItem.name ?? completion.title,
            address: address,
            latitude: CLLocationCoordinate2DIsValid(coordinate) ? coordinate.latitude : nil,
            longitude: CLLocationCoordinate2DIsValid(coordinate) ? coordinate.longitude : nil,
            externalId: placemark.title
        )
    }

    private static func addressString(from placemark: MKPlacemark, fallback: String) -> String? {
        let street = [placemark.thoroughfare, placemark.subThoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        let components = [
            placemark.administrativeArea,
            placemark.locality,
            placemark.subLocality,
            street.isEmpty ? nil : street
        ]
        let address = components
            .compactMap { $0 }
            .joined(separator: " ")
        if !address.isEmpty {
            return address
        }
        return fallback.isEmpty ? nil : fallback
    }

    private static var koreaRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.35, longitude: 127.85),
            span: MKCoordinateSpan(latitudeDelta: 5.8, longitudeDelta: 4.8)
        )
    }
}
