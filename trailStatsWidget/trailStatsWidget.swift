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
                    .foregroundColor(Color("StravaOrange"))
                Text(NSLocalizedString("widget.title", comment: ""))
                    .font(.headline)
                    .bold()
            }
            
            if let activity = entry.activity {
                let distanceValue = isMetric ? activity.distance / 1000 : activity.distance / 1609.34
                let distanceUnit = isMetric ? NSLocalizedString("widget.unit.distance.metric", comment: "") : NSLocalizedString("widget.unit.distance.imperial", comment: "")
                
                let elevationValue = isMetric ? activity.elevation : activity.elevation * 3.28084
                let elevationUnit = isMetric ? NSLocalizedString("widget.unit.elevation.metric", comment: "") : NSLocalizedString("widget.unit.elevation.imperial", comment: "")

                VStack(alignment: .leading, spacing: 4) {
                    Label(String(format: "%.2f \(distanceUnit)", distanceValue), systemImage: "map.fill")
                    Label(String(format: "%.0f \(elevationUnit)", elevationValue), systemImage: "arrow.up.right.circle.fill")
                    Label(activity.duration.formattedAsHMS(), systemImage: "clock.fill")
                }
                .font(.subheadline)
            } else {
                Text(NSLocalizedString("widget.no_activity", comment: ""))
                    .font(.subheadline)
            }
        }
        .padding()
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
        .configurationDisplayName(NSLocalizedString("widget.title", comment: ""))
        .description(NSLocalizedString("widget.description", comment: ""))
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