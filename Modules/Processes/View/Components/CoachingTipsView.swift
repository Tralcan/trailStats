
import SwiftUI

struct CoachingTipsView: View {
    let importante: String
    let nutricion: String

    var body: some View {
        let importanteTips = importante.components(separatedBy: "\n").filter { !$0.isEmpty }
        let nutricionTips = nutricion.components(separatedBy: "\n").filter { !$0.isEmpty }

        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                if !importanteTips.isEmpty {
                    Text("Importante")
                        .font(.headline)
                        .padding(.bottom, 5)

                    ForEach(importanteTips, id: \.self) {
                        tip in
                        Text("• " + tip)
                            .font(.subheadline)
                    }
                }

                if !nutricionTips.isEmpty {
                    Text("Nutrición")
                        .font(.headline)
                        .padding(.top, 10)
                        .padding(.bottom, 5)

                    ForEach(nutricionTips, id: \.self) {
                        tip in
                        Text("• " + tip)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: 300, maxHeight: 400) // Ajusta el tamaño del popover
    }
}

struct CoachingTipsView_Previews: PreviewProvider {
    static var previews: some View {
        CoachingTipsView(
            importante: "- Mantén una hidratación constante desde el inicio, no esperes a tener sed. \n- Gestiona tu energía, no salgas demasiado rápido.  \n- Evalúa el terreno; adapta tu ritmo a los cambios de pendiente para evitar el agotamiento prematuro. \n- Conoce la ruta previamente; esto te permitirá anticipar las dificultades y gestionar tu energía en consecuencia. \n- Enfócate en una técnica de carrera eficiente; esto te ayudará a conservar energía y minimizar el riesgo de lesiones. \n-  Prepara un plan B ante imprevistos; esto te permitirá controlar la situación y reducir la presión.",
            nutricion: "Prioriza una estrategia de nutrición consistente con tu entrenamiento y tu cuerpo. Experimenta con geles, barritas energéticas, bebidas isotónicas y frutos secos en tus entrenamientos largos para determinar qué funciona mejor para ti.  Recuerda ingerir pequeñas cantidades de alimentos cada 30-45 minutos durante la carrera para mantener tus niveles de energía."
        )
    }
}
