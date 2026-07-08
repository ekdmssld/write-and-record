import SwiftUI
import MapKit

struct PlaceMapMarker: Identifiable {
    let id: String
    let primaryEntryId: String
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let coverAsset: MediaAsset?
    let badgeCount: Int

    init?(
        id: String,
        primaryEntryId: String,
        title: String,
        subtitle: String?,
        coordinate: CLLocationCoordinate2D,
        coverAsset: MediaAsset?,
        badgeCount: Int
    ) {
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        self.id = id
        self.primaryEntryId = primaryEntryId
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.coverAsset = coverAsset
        self.badgeCount = max(1, badgeCount)
    }

    init?(entry: Entry, coverAsset: MediaAsset? = nil, badgeCount: Int = 1) {
        guard let place = entry.place,
              let latitude = place.latitude,
              let longitude = place.longitude else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        self.init(
            id: entry.id,
            primaryEntryId: entry.id,
            title: place.name,
            subtitle: place.address,
            coordinate: coordinate,
            coverAsset: coverAsset,
            badgeCount: badgeCount
        )
    }
}

enum PlaceMapPinStyle {
    case system
    case photo
}

struct PlaceMapView: View {
    let markers: [PlaceMapMarker]
    var pinStyle: PlaceMapPinStyle = .system
    var onMarkerTap: ((PlaceMapMarker) -> Void)?

    @State private var position: MapCameraPosition

    init(
        markers: [PlaceMapMarker],
        pinStyle: PlaceMapPinStyle = .system,
        onMarkerTap: ((PlaceMapMarker) -> Void)? = nil
    ) {
        self.markers = markers
        self.pinStyle = pinStyle
        self.onMarkerTap = onMarkerTap
        _position = State(initialValue: .region(Self.region(for: markers)))
    }

    var body: some View {
        Map(position: $position) {
            if pinStyle == .photo {
                ForEach(markers) { marker in
                    Annotation(marker.title, coordinate: marker.coordinate, anchor: .bottom) {
                        photoAnnotation(for: marker)
                    }
                }
            } else {
                ForEach(markers) { marker in
                    Marker(marker.title, systemImage: "mappin.circle.fill", coordinate: marker.coordinate)
                        .tint(AppColors.primary)
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    @ViewBuilder
    private func photoAnnotation(for marker: PlaceMapMarker) -> some View {
        if let onMarkerTap {
            Button {
                onMarkerTap(marker)
            } label: {
                PlacePhotoMapPin(marker: marker)
            }
            .buttonStyle(.plain)
        } else {
            PlacePhotoMapPin(marker: marker)
        }
    }

    private static func region(for markers: [PlaceMapMarker]) -> MKCoordinateRegion {
        guard !markers.isEmpty else {
            return koreaRegion
        }

        let coordinates = markers.map(\.coordinate)
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? coordinates[0].latitude
        let maxLatitude = latitudes.max() ?? coordinates[0].latitude
        let minLongitude = longitudes.min() ?? coordinates[0].longitude
        let maxLongitude = longitudes.max() ?? coordinates[0].longitude

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )
        let latitudeDelta = max(0.01, (maxLatitude - minLatitude) * 1.5)
        let longitudeDelta = max(0.01, (maxLongitude - minLongitude) * 1.5)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }

    private static var koreaRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.35, longitude: 127.85),
            span: MKCoordinateSpan(latitudeDelta: 5.8, longitudeDelta: 4.8)
        )
    }
}

private struct PlacePhotoMapPin: View {
    let marker: PlaceMapMarker

    private var badgeText: String {
        marker.badgeCount > 99 ? "99+" : "\(marker.badgeCount)"
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let coverAsset = marker.coverAsset {
                        AssetThumbnailView(asset: coverAsset, placeholderColorHex: "#A4AAAA")
                    } else {
                        ZStack {
                            AppColors.surface
                            AppColors.category("#A4AAAA").opacity(0.22)
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                }
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.22), radius: 5, x: 0, y: 3)

                Text(badgeText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, marker.badgeCount > 99 ? 6 : 7)
                    .frame(height: 24)
                    .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.white, lineWidth: 1.5)
                    )
                    .offset(x: 10, y: -10)
            }

            Circle()
                .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
                .offset(y: -2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(marker.title), \(marker.badgeCount)개")
    }
}
