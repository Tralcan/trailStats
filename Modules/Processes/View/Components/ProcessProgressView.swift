import SwiftUI

struct ProcessProgressView: View {
    let process: TrainingProcess

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progreso del Proceso")
                .font(.title3).bold()

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Línea de progreso (fondo)
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 10)

                    // Línea de progreso (relleno)
                    Capsule()
                        .fill(Color.accentColor) // O el color que prefieras para el progreso
                        .frame(width: geometry.size.width * CGFloat(progress), height: 10)

                    // Icono de persona
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.blue).frame(width: 30, height: 30))
                        .offset(x: (geometry.size.width * CGFloat(progress)) - 15) // Centrar el icono
                }
            }
            .frame(height: 30) // Altura para contener la línea y el icono

            Text("Completado: \(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private var progress: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: process.startDate)
        let end = calendar.startOfDay(for: process.endDate)

        guard start <= end else { return 0.0 } // Evitar división por cero o rangos inválidos

        let totalDays = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        let elapsedDays = calendar.dateComponents([.day], from: start, to: today).day ?? 0

        if totalDays <= 0 { return 0.0 } // Si el proceso dura 0 días o menos
        if elapsedDays <= 0 { return 0.0 } // Si aún no ha empezado

        let calculatedProgress = Double(elapsedDays) / Double(totalDays)
        return min(max(calculatedProgress, 0.0), 1.0) // Asegurar que el progreso esté entre 0 y 1
    }
}