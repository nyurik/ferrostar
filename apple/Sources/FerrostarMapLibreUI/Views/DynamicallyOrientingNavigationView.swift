import FerrostarCore
import FerrostarSwiftUI
import MapKit
import MapLibre
import MapLibreSwiftDSL
import MapLibreSwiftUI
import SwiftUI

/// A navigation view that dynamically switches between portrait and landscape orientations.
public struct DynamicallyOrientingNavigationView: View {
    // TODO: Add orientation handling once the landscape view is constructed.
    @State private var orientation = UIDeviceOrientation.unknown

    let styleURL: URL
    let distanceFormatter: Formatter
    // TODO: Configurable camera and user "puck" rotation modes

    private var navigationState: NavigationState?
    private let userLayers: [StyleLayerDefinition]

    @State private var locationManager = StaticLocationManager(initialLocation: CLLocation())
    @Binding var camera: MapViewCamera
    @Binding var snappedZoom: Double
    @Binding var useSnappedCamera: Bool

    /// Initialize a map view tuned for turn by turn navigation.
    ///
    /// - Parameters:
    ///   - styleURL: The style URL for the map. This can dynamically change between light and dark mode.
    ///   - navigationState: The ferrostar navigations state. This is used primarily to drive user location on the map.
    ///   - camera: The camera which is controlled by the navigation state, but may also be pushed to for other cases
    /// (e.g. user pan).
    ///   - snappedZoom: The zoom for the snapped camera. This can be fixed, customized or controlled by the camera.
    ///   - useSnappedCamera: Whether to use the ferrostar snapped camera or the camer binding itself.
    ///   - distanceFormatter: The formatter for distances in instruction views.
    public init(
        styleURL: URL,
        navigationState: NavigationState?,
        camera: Binding<MapViewCamera>,
        snappedZoom: Binding<Double>,
        useSnappedCamera: Binding<Bool>,
        distanceFormatter: Formatter = MKDistanceFormatter(),
        @MapViewContentBuilder _ makeMapContent: () -> [StyleLayerDefinition] = { [] }
    ) {
        self.styleURL = styleURL
        self.navigationState = navigationState
        self.distanceFormatter = distanceFormatter
        userLayers = makeMapContent()
        _camera = camera
        _snappedZoom = snappedZoom
        _useSnappedCamera = useSnappedCamera
    }

    public var body: some View {
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            Text("TODO")
        default:
            PortraitNavigationView(
                styleURL: styleURL,
                navigationState: navigationState,
                camera: $camera,
                snappedZoom: $snappedZoom,
                useSnappedCamera: $useSnappedCamera,
                distanceFormatter: distanceFormatter
            ) {
                userLayers
            }
        }
    }
}

#Preview("Portrait Navigation View (Imperial)") {
    // TODO: Make map URL configurable but gitignored
    let state = NavigationState.modifiedPedestrianExample(droppingNWaypoints: 4)
    let formatter = MKDistanceFormatter()
    formatter.locale = Locale(identifier: "en-US")
    formatter.units = .imperial

    return DynamicallyOrientingNavigationView(
        styleURL: URL(string: "https://demotiles.maplibre.org/style.json")!,
        navigationState: state,
        camera: .constant(.center(state.snappedLocation.clLocation.coordinate, zoom: 12)),
        snappedZoom: .constant(18),
        useSnappedCamera: .constant(true),
        distanceFormatter: formatter
    )
}

#Preview("Portrait Navigation View (Metric)") {
    // TODO: Make map URL configurable but gitignored
    let state = NavigationState.modifiedPedestrianExample(droppingNWaypoints: 4)
    let formatter = MKDistanceFormatter()
    formatter.locale = Locale(identifier: "en-US")
    formatter.units = .metric

    return DynamicallyOrientingNavigationView(
        styleURL: URL(string: "https://demotiles.maplibre.org/style.json")!,
        navigationState: state,
        camera: .constant(.center(state.snappedLocation.clLocation.coordinate, zoom: 12)),
        snappedZoom: .constant(18),
        useSnappedCamera: .constant(true),
        distanceFormatter: formatter
    )
}
