import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ProcessWidgetProvider: TimelineProvider {
    let dataProvider = ProcessWidgetDataProvider()

    func placeholder(in context: Context) -> ProcessEntry {
        ProcessEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ProcessEntry) -> ()) {
        let entry = ProcessEntry(date: Date(), processData: dataProvider.fetchActiveProcessData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProcessEntry>) -> ()) {
        let entry = ProcessEntry(date: Date(), processData: dataProvider.fetchActiveProcessData())
        
        // Refresh the widget every hour to keep the days remaining up to date.
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct ProcessEntry: TimelineEntry {
    let date: Date
    let processData: ProcessWidgetData?

    static var placeholder: ProcessEntry {
        ProcessEntry(date: Date(), processData: .init(processName: "UTMB 2026", daysRemaining: 89, daysRemainingText: "Days Remaining", distanceValue: 171, distanceUnit: "km", elevationValue: 10000, elevationUnit: "m", estimatedTime: "28:30:00"))
    }
}

// MARK: - Widget View

struct ProcessWidgetEntryView : View {
    var entry: ProcessWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let data = entry.processData {
                // Header
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.accentColor)
                    Text(data.processName)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Divider()

                // Countdown
                HStack {
                    Text("process_widget.days_remaining")
                        .font(.caption)
                    Spacer()
                    Text("\(data.daysRemaining)")
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundColor(.accentColor)
                }

                // Goal Stats
                Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 4) {
                    GridRow {
                        Image(systemName: "map.fill")
                            .foregroundColor(Color("StravaOrange"))
                        Text(String(format: "%.1f ", data.distanceValue))
                        + Text(data.distanceUnit)
                    }
                    
                    GridRow {
                        Image(systemName: "triangle.fill")
                            .foregroundColor(.green)
                        Text(String(format: "%.0f ", data.elevationValue))
                        + Text(data.elevationUnit)
                    }

                    GridRow {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text(data.estimatedTime)
                    }
                }
                .font(.footnote)

            } else {
                // Placeholder for no active process
                VStack {
                    Image(systemName: "moon.zzz.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("process_widget.no_process")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Widget Configuration

struct ProcessWidget: Widget {
    let kind: String = "ProcessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProcessWidgetProvider()) { entry in
            ProcessWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("process_widget.title")
        .description("process_widget.description")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    ProcessWidget()
} timeline: {
    ProcessEntry.placeholder
    ProcessEntry(date: Date(), processData: nil)
}
