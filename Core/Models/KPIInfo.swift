import Foundation

enum KPITrend {
    case up, down, equal
}

/// Data model for a Key Performance Indicator (KPI).
struct KPIInfo: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let value: Double?
    let trend: KPITrend?
    let higherIsBetter: Bool

    init(title: String, description: String, value: Double? = nil, trend: KPITrend? = nil, higherIsBetter: Bool) {
        self.title = title
        self.description = description
        self.value = value
        self.trend = trend
        self.higherIsBetter = higherIsBetter
    }

    static func == (lhs: KPIInfo, rhs: KPIInfo) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Analytics KPIs
    static let aerobicEfficiency = KPIInfo(
        title: "Eficiencia Aeróbica (EF)",
        description: "Mide tu producción de velocidad (ritmo) por cada latido del corazón. Un valor más alto indica una mejor eficiencia aeróbica. Se calcula como tu ritmo en metros por minuto dividido por tu frecuencia cardíaca media. Es ideal para seguir tu progreso aeróbico a lo largo del tiempo con esfuerzos a una intensidad similar.",
        higherIsBetter: true
    )

    static let trainingLoadCTL = KPIInfo(
        title: "Carga de Entrenamiento (CTL - Chronic Training Load)",
        description: "También conocido como 'Fitness', es una media ponderada de tu carga de entrenamiento durante los últimos 42 días. Refleja la carga de entrenamiento que puedes soportar de forma consistente. Un CTL en aumento indica una mejora de la condición física.",
        higherIsBetter: true
    )

    static let fatigueATL = KPIInfo(
        title: "Fatiga (ATL - Acute Training Load)",
        description: "También conocido como 'Fatiga', es una media ponderada de tu carga de entrenamiento durante los últimos 7 días. Refleja la fatiga acumulada por tus entrenamientos recientes.",
        higherIsBetter: false // Higher fatigue is generally not "better"
    )

    // MARK: - Trail Performance KPIs
    static let vam = KPIInfo(
        title: "Velocidad de Ascenso Media (VAM)",
        description: "Mide tu velocidad de ascenso en metros por hora (m/h). Es un indicador clave del rendimiento en subida. Se calcula promediando la velocidad vertical solo en los tramos de pendiente positiva.",
        higherIsBetter: true
    )

    static let gap = KPIInfo(
        title: "Ritmo Ajustado por Pendiente (GAP)",
        description: "Estima tu ritmo equivalente en terreno llano, teniendo en cuenta la dificultad añadida de las subidas y bajadas. Te permite comparar esfuerzos en rutas con diferentes perfiles de elevación.",
        higherIsBetter: false // Lower pace (time) is better
    )

    static let descentVam = KPIInfo(
        title: "Velocidad de Descenso Media",
        description: "Mide tu velocidad de descenso en metros por hora (m/h). Es un indicador de tu habilidad y confianza bajando. Se calcula promediando la velocidad vertical solo en los tramos de pendiente negativa.",
        higherIsBetter: true
    )

    static let normalizedPower = KPIInfo(
        title: "Potencia Normalizada (NP)",
        description: "Una estimación de la potencia que podrías haber mantenido para el mismo coste fisiológico si tu producción de potencia hubiera sido perfectamente constante. Es una mejor medida del esfuerzo real en entrenamientos con variaciones de intensidad que la potencia media.",
        higherIsBetter: true
    )

    static let efficiencyIndex = KPIInfo(
        title: "Índice de Eficiencia (EI)",
        description: "Mide la relación entre tu Potencia Normalizada (NP) y tu frecuencia cardíaca media. Un EI más alto sugiere una mejor eficiencia cardiovascular: produces más potencia para un mismo esfuerzo cardíaco. Se calcula como NP / Frecuencia Cardíaca Media.",
        higherIsBetter: true
    )

    static let decoupling = KPIInfo(
        title: "Desacoplamiento Aeróbico (Pa:Hr)",
        description: "Mide cuánto se 'desacopla' tu frecuencia cardíaca de tu ritmo (o potencia) a lo largo de una actividad. Se calcula comparando el Índice de Eficiencia de la primera mitad de la actividad con el de la segunda. Un valor bajo (típicamente < 5%) indica una buena resistencia aeróbica.",
        higherIsBetter: false // Lower decoupling is better
    )

    // MARK: - Running Dynamics KPIs
    static let verticalOscillation = KPIInfo(
        title: "Oscilación Vertical",
        description: "Mide el 'rebote' vertical de tu torso en cada paso, en centímetros. Una menor oscilación suele indicar una carrera más eficiente, ya que se desperdicia menos energía en movimiento hacia arriba y hacia abajo.",
        higherIsBetter: false // Lower oscillation is better
    )

    static let groundContactTime = KPIInfo(
        title: "Tiempo de Contacto con el Suelo (GCT)",
        description: "El tiempo que tu pie pasa en contacto con el suelo en cada paso, medido en milisegundos. Tiempos de contacto más bajos suelen estar asociados con una mayor eficiencia y una cadencia más alta.",
        higherIsBetter: false // Lower GCT is better
    )

    static let strideLength = KPIInfo(
        title: "Longitud de Zancada",
        description: "La distancia que recorres entre un paso y el siguiente, medida en metros. Varía con el ritmo, la pendiente y la fatiga.",
        higherIsBetter: true // Generally, for a given pace, longer stride is more efficient, but it's complex.
    )

    static let verticalRatio = KPIInfo(
        title: "Ratio Vertical",
        description: "La relación entre tu oscilación vertical y tu longitud de zancada, expresada como un porcentaje. Un ratio más bajo indica que estás usando más energía para avanzar hacia adelante y menos para rebotar, lo que es más eficiente. Se calcula como (Oscilación Vertical / Longitud de Zancada) * 100.",
        higherIsBetter: false // Lower ratio is better
    )
}
