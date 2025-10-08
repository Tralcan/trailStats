import WidgetKit
import SwiftUI

// 1. El modelo de datos para la Timeline del Widget
struct SimpleEntry: TimelineEntry {
    let date: Date
    let activity: ActivitySummary?

    static func placeholder() -> SimpleEntry {
        SimpleEntry(date: Date(), activity: ActivitySummary.placeholder())
    }
}

// 2. El proveedor de datos que genera la Timeline
struct Provider: TimelineProvider {
    // Instancia del proveedor de datos para el widget
    let dataProvider = WidgetDataProvider()

    // Una vista previa del widget para la galería
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry.placeholder()
    }

    // La vista para un momento específico (snapshot)
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let activitySummary = dataProvider.loadActivityForWidget()
        let entry = SimpleEntry(date: Date(), activity: activitySummary)
        completion(entry)
    }

    // La timeline completa del widget (cuándo actualizar)
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let activitySummary = dataProvider.loadActivityForWidget()
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, activity: activitySummary)

        // Define la política de actualización: cada hora
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

// 3. La vista de SwiftUI que se muestra en el Widget
struct trailStatsWidgetEntryView : View {
    var entry: Provider.Entry
    private let isMetric = Locale.current.usesMetricSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "figure.run.circle.fill")
                    .foregroundColor(.primary)
                Text("widget.title")
                    .font(.headline)
                    .bold()
            }
            
            if let activity = entry.activity {
                let distanceValue = isMetric ? activity.distance / 1000 : activity.distance / 1609.34
                let distanceUnit: LocalizedStringKey = isMetric ? "widget.unit.distance.metric" : "widget.unit.distance.imperial"
                
                let elevationValue = isMetric ? activity.elevation : activity.elevation * 3.28084
                let elevationUnit: LocalizedStringKey = isMetric ? "widget.unit.elevation.metric" : "widget.unit.elevation.imperial"

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(Color("StravaOrange"))
                        Text(String(format: "%.2f ", distanceValue))
                        + Text(distanceUnit)
                    }
                    HStack {
                        Image(systemName: "triangle.fill")
                            .foregroundColor(.green)
                        Text(String(format: "%.0f ", elevationValue))
                        + Text(elevationUnit)
                    }
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text(activity.duration.formattedAsHMS())
                    }
                }
                .font(.subheadline)
            } else {
                Text("widget.no_activity")
                    .font(.subheadline)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// 4. La configuración principal del Widget
struct trailStatsWidget: Widget {
    let kind: String = "trailStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            trailStatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget.title")
        .description("widget.description")
        .supportedFamilies([.systemSmall])
    }
}

// 5. Preview para el desarrollo en Xcode
struct trailStatsWidget_Previews: PreviewProvider {
    static var previews: some View {
        trailStatsWidgetEntryView(entry: SimpleEntry.placeholder())
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
