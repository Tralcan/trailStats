import SwiftUI

/// Una vista de gráfico interactivo que muestra un perfil de altimetría base
/// y permite al usuario seleccionar una métrica adicional para superponer y analizar.
struct InteractiveChartView: View {
    
    // MARK: - Propiedades de Entrada
    
    /// Los datos de altimetría que siempre se muestran.
    let altitudeData: [ChartDataPoint]
    
    /// Un diccionario con las series de datos que el usuario puede seleccionar.
    /// La clave es el nombre de la métrica (ej. "Ritmo").
    let overlayData: [String: [ChartDataPoint]]
    
    /// Un diccionario que asocia un color a cada métrica.
    let overlayColors: [String: Color]
    
    /// Un diccionario que define la unidad para cada métrica.
    let overlayUnits: [String: String]

    // MARK: - Estado Interno
    
    /// La clave de la métrica actualmente seleccionada por el usuario.
    @State private var selectedOverlayKey: String

    /// Las claves de las métricas disponibles, ordenadas alfabéticamente para consistencia.
    private var overlayKeys: [String] {
        overlayData.keys.sorted()
    }

    // MARK: - Inicializador
    
    init(altitudeData: [ChartDataPoint], overlayData: [String: [ChartDataPoint]], overlayColors: [String: Color], overlayUnits: [String: String]) {
        self.altitudeData = altitudeData
        self.overlayData = overlayData
        self.overlayColors = overlayColors
        self.overlayUnits = overlayUnits
        // Inicializa el estado con la primera métrica disponible.
        self._selectedOverlayKey = State(initialValue: overlayData.keys.sorted().first ?? "")
    }

    // MARK: - Cuerpo de la Vista
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Análisis Interactivo")
                .font(.title2).bold()

            // Selector de métrica
            Picker("Métrica", selection: $selectedOverlayKey) {
                ForEach(overlayKeys, id: \.self) { key in
                    Text(key)
                }
            }
            .pickerStyle(.segmented)
            
            // Gráfico para la métrica seleccionada
            if let selectedData = overlayData[selectedOverlayKey],
               let color = overlayColors[selectedOverlayKey],
               let unit = overlayUnits[selectedOverlayKey] {
                
                if !selectedData.isEmpty {
                    TimeSeriesChartView(
                        data: selectedData,
                        title: selectedOverlayKey,
                        yAxisLabel: unit,
                        color: color,
                        showAverage: true,
                        normalize: true
                    )
                    .frame(height: 150)
                } else {
                    placeholderView(for: selectedOverlayKey)
                }
            }
            
            // Gráfico para el perfil de altimetría
            if !altitudeData.isEmpty {
                TimeSeriesChartView(
                    data: altitudeData,
                    title: "Perfil de Altimetría",
                    yAxisLabel: "m",
                    color: .purple,
                    showAverage: false,
                    normalize: false
                )
                .frame(height: 120)
            } else {
                placeholderView(for: "Altimetría")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    /// Vista de marcador de posición para cuando no hay datos de gráfico.
    private func placeholderView(for metricName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
            Text("No hay datos para \(metricName)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 120)
    }
}
