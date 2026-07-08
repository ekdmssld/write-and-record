import SwiftUI
import MapKit

struct PlaceMapMarker: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D

    init?(entry: Entry) {
        guard let place = entry.place,
              let latitude = place.latitude,
              let longitude = place.longitude else { return nil }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }

        id = entry.id
        title = place.name
        subtitle = place.address
        self.coordinate = coordinate
    }
}

struct PlaceMapView: View {
    let markers: [PlaceMapMarker]

    @State private var position: MapCameraPosition

    init(markers: [PlaceMapMarker]) {
        self.markers = markers
        _position = State(initialValue: .region(Self.region(for: markers)))
    }

    var body: some View {
        Map(position: $position) {
            ForEach(markers) { marker in
                Marker(marker.title, systemImage: "mappin.circle.fill", coordinate: marker.coordinate)
                    .tint(AppColors.primary)
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    private static func region(for markers: [PlaceMapMarker]) -> MKCoordinateRegion {
        guard !markers.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
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
}
