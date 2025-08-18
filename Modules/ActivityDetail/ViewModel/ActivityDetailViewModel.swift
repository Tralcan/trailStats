
import SwiftUI

/// A ViewModel for the ActivityDetailView.
/// It simply holds the activity to be displayed.
class ActivityDetailViewModel: ObservableObject {
    @Published var activity: Activity
    
    init(activity: Activity) {
        self.activity = activity
    }
}
