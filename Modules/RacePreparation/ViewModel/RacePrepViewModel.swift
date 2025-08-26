
import Foundation

class RacePrepViewModel: ObservableObject {
    @Published var races: [Race] = [] {
        didSet {
            saveRaces()
        }
    }

    private let userDefaultsKey = "savedRaces"

    init() {
        loadRaces()
    }

    func addRace(name: String, distance: Double, elevationGain: Double, date: Date) {
        let newRace = Race(name: name, distance: distance, elevationGain: elevationGain, date: date)
        races.append(newRace)
    }

    private func saveRaces() {
        if let encoded = try? JSONEncoder().encode(races) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadRaces() {
        if let savedRacesData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let decodedRaces = try? JSONDecoder().decode([Race].self, from: savedRacesData) {
                self.races = decodedRaces
            }
        }
    }
}
