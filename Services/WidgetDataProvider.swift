
import Foundation

// Un proveedor de datos simple solo para el uso del Widget.
class WidgetDataProvider {
    private var widgetActivityFileURL: URL? {
        let appGroupId = "group.com.danguita.trailStats"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("[WidgetDataProvider] ERROR: No se pudo obtener URL del App Group (\(appGroupId))")
            return nil
        }
        return groupURL.appendingPathComponent("latest_widget_activity.json")
    }

    func loadActivityForWidget() -> ActivitySummary? {
        guard let url = widgetActivityFileURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ActivitySummary.self, from: data)
        } catch {
            print("[WidgetDataProvider] Error cargando y decodificando latest_widget_activity.json: \(error.localizedDescription)")
            return nil
        }
    }
}
