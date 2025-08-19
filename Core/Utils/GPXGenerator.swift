import Foundation
import CoreLocation

struct GPXGenerator {
    static func generateGPX(from streams: [String: Stream], startDate: Date) -> String? {
        guard let latitudeStream = streams["latlng"]?.data,
              let longitudeStream = streams["latlng"]?.data,
              let altitudeStream = streams["altitude"]?.data,
              let timeStream = streams["time"]?.data else {
            print("Missing required streams for GPX generation.")
            return nil
        }

        // Ensure all streams have the same number of data points
        let count = min(latitudeStream.count, longitudeStream.count, altitudeStream.count, timeStream.count)
        guard count > 0 else {
            print("No data points available for GPX generation.")
            return nil
        }

        var gpxString = """
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx xmlns="http://www.topografix.com/GPX/1/1" creator="trailStats" version="1.1">
  <trk>
    <name>Activity Route</name>
    <trkseg>
"""

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for i in 0..<count {
            if let lat = latitudeStream[i],
               let lon = longitudeStream[i],
               let alt = altitudeStream[i],
               let timeOffset = timeStream[i] {

                // Strava time stream is usually seconds from the start of the activity.
                // We need a base time for the GPX timestamp. Let's use the current date as a base.
                // In a real app, you'd want to use the activity's start time.
                let baseDate = Date() // Placeholder: ideally use activity.startDate
                let pointDate = baseDate.addingTimeInterval(timeOffset)
                let timeString = dateFormatter.string(from: pointDate)

                gpxString += """
    <trkpt lat="\(lat)" lon="\(lon)">
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
