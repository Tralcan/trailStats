import Foundation

// MARK: - Widget Data Structures

/// Holds the consolidated, pre-localized data ready for the Process Widget view.
struct ProcessWidgetData: Codable {
    let processName: String
    let daysRemaining: Int
    let daysRemainingText: String // Pre-localized "Days Remaining"
    
    let distanceValue: Double
    let distanceUnit: String // Pre-localized "km" or "mi"
    
    let elevationValue: Double
    let elevationUnit: String // Pre-localized "m" or "ft"
    
    let estimatedTime: String
}

/// This class is responsible for fetching and processing all data needed for the Process Widget.
class ProcessWidgetDataProvider {

    private var processWidgetFileURL: URL? {
        let appGroupId = "group.com.danguita.trailStats"
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            print("[ProcessWidgetDataProvider] ERROR: No se pudo obtener URL del App Group (\(appGroupId))")
            return nil
        }
        return groupURL.appendingPathComponent("active_process_widget.json")
    }

    func fetchActiveProcessData() -> ProcessWidgetData? {
        print("\n--- DEBUG PROCESS WIDGET: LOAD ---")
        guard let url = processWidgetFileURL else {
            print("🔴 ERROR: La URL del fichero del widget es nula.")
            print("--- END DEBUG ---\n")
            return nil
        }
        print("🔍 Intentando leer datos desde: \(url.path)")

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("🟡 AVISO: No se encontró el fichero active_process_widget.json en la ruta.")
            print("--- END DEBUG ---\n")
            return nil
        }
        print("✅ Fichero encontrado.")

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let processData = try decoder.decode(ProcessWidgetData.self, from: data)
            print("✅ Datos decodificados correctamente para el proceso: '\(processData.processName)'.")
            print("--- END DEBUG ---\n")
            return processData
        } catch {
            print("🔴 ERROR: Fallo al decodificar active_process_widget.json: \(error.localizedDescription)")
            print("--- END DEBUG ---\n")
            return nil
        }
    }
}
