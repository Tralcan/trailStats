import SwiftUI
struct RacePrepView: View {
    @StateObject private var viewModel = RacePrepViewModel()
    @State private var showingAddRaceSheet = false
    @State private var selectedRace: Race? = nil // New state for selected race

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.races.isEmpty {
                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Race Preparation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("The AI-powered race preparation module is coming soon!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    List {
                        ForEach(viewModel.races) {
                            race in
                            Button(action: {
                                selectedRace = race
                            }) {
                                HStack {
                                    Image(systemName: "medal.fill") // Icono de medalla grande
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40) // Ajustar tamaño
                                        .foregroundColor(.yellow)
                                        .padding(.trailing, 8)

                                    VStack(alignment: .leading) {
                                        HStack {
                                            Text(race.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text("\(daysRemaining(for: race.date)) días") // Días restantes
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        HStack {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(.red)
                                            Text("\(String(format: "%.2f", race.distance / 1000)) km")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Image(systemName: "mountain.2.fill")
                                                .foregroundColor(.green)
                                            Text("\(String(format: "%.0f", race.elevationGain)) m")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4) // Ajustar padding vertical
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 8)
            .navigationTitle("Races")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Agregar Carrera") {
                        showingAddRaceSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingAddRaceSheet) {
                AddRaceView(viewModel: viewModel, isShowingSheet: $showingAddRaceSheet)
            }
            .sheet(item: $selectedRace) { race in
                RaceDetailView(viewModel: viewModel, race: race)
            }
        }
    }

    private func daysRemaining(for date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let raceDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: today, to: raceDay)
        return components.day ?? 0
    }
} // Cierre de RacePrepView

#Preview {
    RacePrepView()
}

struct AddRaceView: View {
    @ObservedObject var viewModel: RacePrepViewModel
    @Binding var isShowingSheet: Bool

    @State private var raceName: String = ""
    @State private var raceDistance: String = ""
    @State private var raceElevationGain: String = ""
    @State private var raceDate: Date = Date() // New state for race date

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles de la Carrera")) {
                    HStack {
                        Image(systemName: "medal.fill") // Icono de medalla para el nombre de la carrera
                            .foregroundColor(.yellow) // Color amarillo para la medalla
                        TextField("Nombre de la Carrera", text: $raceName)
                            .autocorrectionDisabled()
                    }
                    HStack {
                        Image(systemName: "location.fill") // Usar el mismo icono para distancia
                            .foregroundColor(.red)
                        TextField("Distancia (kilómetros)", text: $raceDistance)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Image(systemName: "mountain.2.fill")
                            .foregroundColor(.green)
                        TextField("Desnivel Acumulado (metros)", text: $raceElevationGain)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Image(systemName: "clock.fill") // Icono de reloj para la fecha
                            .foregroundColor(.blue)
                        DatePicker("Fecha de la Carrera", selection: $raceDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Nueva Carrera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        isShowingSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        if let distanceKm = Double(raceDistance),
                           let elevationGain = Double(raceElevationGain) {
                            // Convertir kilómetros a metros antes de guardar
                            viewModel.addRace(name: raceName, distance: distanceKm * 1000, elevationGain: elevationGain, date: raceDate)
                            isShowingSheet = false
                        }
                    }
                    .disabled(raceName.isEmpty || raceDistance.isEmpty || raceElevationGain.isEmpty)
                }
            }
        }
    }
}

struct RaceDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: RacePrepViewModel
    let race: Race
    @State private var geminiResponse: RaceGeminiCoachResponse? = nil
    @State private var showingDeleteConfirmation = false
    private let geminiCoachService = RaceGeminiCoachService()
    private let cacheManager = CacheManager()

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // New layout
                        VStack(alignment: .leading) {
                            Text("Carrera")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Text(race.name)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(daysRemaining(for: race.date)) días")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.red)
                                Text("\(String(format: "%.2f", race.distance / 1000)) km")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: "mountain.2.fill")
                                    .foregroundColor(.green)
                                Text("\(String(format: "%.0f", race.elevationGain)) m")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if let response = geminiResponse {
                            VStack(alignment: .center) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.blue)
                                    Text(response.tiempo)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                Text(response.razon)
                                    .font(.caption)
                                    .italic()
                                    .multilineTextAlignment(.center)
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Importante")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(response.importante)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Nutrición")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(response.nutricion)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            HStack {
                                Spacer()
                                VStack(spacing: 10) {
                                    Button(action: {
                                        cacheManager.deleteRaceGeminiCoachResponse(raceId: race.id)
                                        geminiResponse = nil
                                        geminiCoachService.getRaceEstimationAndRecommendations(for: race) { result in
                                            switch result {
                                            case .success(let response):
                                                self.geminiResponse = response
                                            case .failure(let error):
                                                print("Error getting Gemini response: \(error.localizedDescription)")
                                                // Handle error, maybe show an alert
                                            }
                                        }
                                    }) {
                                        Label("Refrescar", systemImage: "arrow.clockwise")
                                    }
                                    .buttonStyle(.bordered)

                                    Button(action: {
                                        showingDeleteConfirmation = true
                                    }) {
                                        Label("Eliminar Carrera", systemImage: "trash")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                if geminiResponse == nil {
                    loadingView
                }
            }
            .navigationTitle("Detalle de Carrera") // Changed navigation title
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                geminiCoachService.getRaceEstimationAndRecommendations(for: race) { result in
                    switch result {
                    case .success(let response):
                        self.geminiResponse = response
                    case .failure(let error):
                        print("Error getting Gemini response: \(error.localizedDescription)")
                        // Handle error, maybe show an alert
                    }
                }
            }
            .alert("Eliminar Carrera", isPresented: $showingDeleteConfirmation) {
                Button("Eliminar", role: .destructive) {
                    viewModel.deleteRace(race: race)
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("¿Estás seguro de que quieres eliminar esta carrera? Esta acción no se puede deshacer.")
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                Text("Estimando predicción...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            .padding(32)
            .background(Material.ultraThinMaterial)
            .cornerRadius(16)
        }
    }

    private func daysRemaining(for date: Date) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let raceDay = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: today, to: raceDay)
        return components.day ?? 0
    }
}

#Preview {
    RaceDetailView(viewModel: RacePrepViewModel(), race: Race(name: "Sample Race", distance: 10000, elevationGain: 500, date: Date()))
}