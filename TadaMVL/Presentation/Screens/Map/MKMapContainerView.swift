import MapKit
import SwiftUI
import UIKit

struct MKMapContainerView: UIViewRepresentable {

    @Binding var region: MKCoordinateRegion
    var showsUserLocation: Bool
    var onMapCenterChanged: (CLLocationCoordinate2D) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(region: $region, onMapCenterChanged: onMapCenterChanged)
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = showsUserLocation
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.region = region
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parentRegion = $region
        context.coordinator.onMapCenterChanged = onMapCenterChanged
        mapView.showsUserLocation = showsUserLocation
        if Self.regionsDiffer(mapView.region, region) {
            mapView.setRegion(region, animated: false)
        }
    }

    // Tight epsilon - we only care about avoiding the feedback loop above,
    // not user-visible drift.
    private static func regionsDiffer(_ a: MKCoordinateRegion, _ b: MKCoordinateRegion) -> Bool {
        abs(a.center.latitude - b.center.latitude) > 0.00002
            || abs(a.center.longitude - b.center.longitude) > 0.00002
            || abs(a.span.latitudeDelta - b.span.latitudeDelta) > 0.000002
            || abs(a.span.longitudeDelta - b.span.longitudeDelta) > 0.000002
    }

    final class Coordinator: NSObject, MKMapViewDelegate {

        var parentRegion: Binding<MKCoordinateRegion>
        var onMapCenterChanged: (CLLocationCoordinate2D) -> Void

        init(
            region: Binding<MKCoordinateRegion>,
            onMapCenterChanged: @escaping (CLLocationCoordinate2D) -> Void
        ) {
            self.parentRegion = region
            self.onMapCenterChanged = onMapCenterChanged
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            let newRegion = mapView.region
            parentRegion.wrappedValue = newRegion
            let center = newRegion.center
            DispatchQueue.main.async {
                self.onMapCenterChanged(center)
            }
        }
    }
}
