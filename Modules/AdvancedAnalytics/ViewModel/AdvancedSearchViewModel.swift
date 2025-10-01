import Foundation
import SwiftUI

class AdvancedSearchViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var date: Date? = nil
    @Published var distance: Double? = nil
    @Published var elevation: Double? = nil
    @Published var duration: TimeInterval? = nil
    @Published var trainingTag: ActivityTag? = nil
    
    var onSearch: ((String, Date?, Double?, Double?, TimeInterval?, ActivityTag?) -> Void)?
    
    init(onSearch: ((String, Date?, Double?, Double?, TimeInterval?, ActivityTag?) -> Void)? = nil) {
        self.onSearch = onSearch
    }
    
    func performSearch() {
        onSearch?(name, date, distance, elevation, duration, trainingTag)
    }
}