import SwiftUI
import MapKit

// The new UIViewRepresentable for the map
struct MapViewWithPolyline: UIViewRepresentable {
    let polylineString: String?
    let is3DEnabled: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .satelliteFlyover
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        guard let polylineString = polylineString else { return }

        // Only update overlay if it has changed
        if context.coordinator.lastPolyline != polylineString {
            // Remove old overlays
            let allOverlays = uiView.overlays
            uiView.removeOverlays(allOverlays)

            // Decode polyline and add new overlay
            if let coordinates = PolylineDecoder.decode(encodedPolyline: polylineString) {
                let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                uiView.addOverlay(polyline)

                // Set region
                if let region = region(for: coordinates) {
                    uiView.setRegion(region, animated: false)
                }
            }
            context.coordinator.lastPolyline = polylineString
        }

        // Update camera for 3D view
        print("updateUIView called. is3DEnabled: \(is3DEnabled)")
        let targetPitch = is3DEnabled ? 45.0 : 0.0
        let currentPitch = uiView.camera.pitch
        print("Current pitch: \(currentPitch), Target pitch: \(targetPitch)")

        if abs(currentPitch - targetPitch) > 0.1 {
            print("Pitch difference is significant, updating camera.")
            
            let existingCamera = uiView.camera
            let newCamera = MKMapCamera(lookingAtCenter: existingCamera.centerCoordinate,
                                        fromDistance: existingCamera.altitude,
                                        pitch: targetPitch,
                                        heading: existingCamera.heading)

            print("Camera before animation: Pitch: \(uiView.camera.pitch), Heading: \(uiView.camera.heading), Altitude: \(uiView.camera.altitude)")
            
            uiView.setCamera(newCamera, animated: true)
        } else {
            print("Pitch difference is not significant, not updating camera.")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        guard let minLat = latitudes.min(), let maxLat = latitudes.max(), let minLon = longitudes.min(), let maxLon = longitudes.max() else {
            return nil
        }

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.4, longitudeDelta: (maxLon - minLon) * 1.4)

        return MKCoordinateRegion(center: center, span: span)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithPolyline
        var lastPolyline: String?

        init(_ parent: MapViewWithPolyline) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(named: "StravaOrange")
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

// The original MapView, now simplified
struct MapView: View {
    var polyline: String?
    @State private var is3DEnabled = false

    var body: some View {
        if let polyline = polyline, !polyline.isEmpty {
            MapViewWithPolyline(polylineString: polyline, is3DEnabled: is3DEnabled)
                .cornerRadius(12)
                .frame(height: 300)
                .overlay(
                    Button(action: {
                        withAnimation {
                            is3DEnabled.toggle()
                        }
                    }) {
                        Image(systemName: is3DEnabled ? "view.3d" : "view.2d")
                            .padding()
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(8)
                    }
                    .padding(10),
                    alignment: .topTrailing
                )
        } else {
            VStack {
                Text(NSLocalizedString("Map not available", comment: "Map not available"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(height: 300)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}
