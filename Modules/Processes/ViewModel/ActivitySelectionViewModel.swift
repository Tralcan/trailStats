import Foundation

@MainActor
class ActivitySelectionViewModel: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let stravaService = StravaService()

    func fetchActivities() {
        isLoading = true
        errorMessage = nil

        stravaService.getActivities(page: 1, perPage: 200) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let activities):
                    self?.activities = activities
                case .failure(let error):
                    self?.errorMessage = "Error al cargar actividades: \(error.localizedDescription)"
                }
            }
        }
    }
}
