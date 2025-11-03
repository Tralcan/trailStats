
import Foundation
import CoreLocation

/// A utility for decoding polylines into a list of coordinates.
///
/// The decoding algorithm is based on Google's encoded polyline format.
/// https://developers.google.com/maps/documentation/utilities/polylinealgorithm
public struct PolylineDecoder {

    /// Decodes a polyline string into an array of `CLLocationCoordinate2D` objects.
    ///
    /// - Parameter encodedPolyline: The encoded polyline string.
    /// - Returns: An array of `CLLocationCoordinate2D` objects, or `nil` if decoding fails.
    public static func decode(encodedPolyline: String) -> [CLLocationCoordinate2D]? {
        guard !encodedPolyline.isEmpty else { return nil }

        var coordinates: [CLLocationCoordinate2D] = []
        var index = encodedPolyline.startIndex
        var lat: Int32 = 0
        var lon: Int32 = 0

        while index < encodedPolyline.endIndex {
            var result: Int32 = 0
            var shift: Int32 = 0
            var b: Int32 = 0

            repeat {
                let charIndex = encodedPolyline[index]
                let ascii = charIndex.asciiValue ?? 0
                b = Int32(ascii) - 63
                result |= (b & 0x1f) << shift
                shift += 5
                index = encodedPolyline.index(after: index)
            } while b >= 0x20

            let dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lat += dlat

            result = 0
            shift = 0
            b = 0

            repeat {
                let charIndex = encodedPolyline[index]
                let ascii = charIndex.asciiValue ?? 0
                b = Int32(ascii) - 63
                result |= (b & 0x1f) << shift
                shift += 5
                index = encodedPolyline.index(after: index)
            } while b >= 0x20

            let dlon = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lon += dlon

            let location = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat) / 1e5,
                                                  longitude: CLLocationDegrees(lon) / 1e5)
            coordinates.append(location)
        }

        return coordinates
    }
}
