import Foundation
import CoreLocation

struct GPXGenerator {
    static func generateGPX(from streams: [String: Stream], startDate: Date) -> String? {
        // Usar latlngData si está disponible, si no, reconstruir desde el array plano
        let latlngPairs: [[Double]]? = streams["latlng"]?.latlngData ?? {
            guard let flat = streams["latlng"]?.data else { return nil }
            var result: [[Double]] = []
            var i = 0
            while i + 1 < flat.count {
                if let lat = flat[i], let lon = flat[i+1] {
                    result.append([lat, lon])
                }
                i += 2
            }
            return result
        }()
        guard let latlng = latlngPairs,
              let altitudeStream = streams["altitude"]?.data,
              let timeStream = streams["time"]?.data else {
            print("Missing required streams for GPX generation.")
            return nil
        }
        let count = min(latlng.count, altitudeStream.count, timeStream.count)
        guard count > 0 else {
            print("No data points available for GPX generation.")
            return nil
        }
        var gpxString = """
<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<gpx xmlns=\"http://www.topografix.com/GPX/1/1\" creator=\"trailStats\" version=\"1.1\">
  <trk>
    <name>Activity Route</name>
    <trkseg>
"""
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for idx in 0..<count {
            let lat = latlng[idx][0]
            let lon = latlng[idx][1]
            if let alt = altitudeStream[idx], let timeOffset = timeStream[idx] {
                let pointDate = startDate.addingTimeInterval(timeOffset)
                let timeString = dateFormatter.string(from: pointDate)
                gpxString += """
    <trkpt lat=\"\(lat)\" lon=\"\(lon)\">
      <ele>\(alt)</ele>
      <time>\(timeString)</time>
    </trkpt>
"""
            }
        }
        gpxString += """
    </trkseg>
  </trk>
</gpx>
"""
        return gpxString
    }
}
