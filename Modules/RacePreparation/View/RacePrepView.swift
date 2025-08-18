
import SwiftUI

struct RacePrepView: View {
    @StateObject private var viewModel = RacePrepViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
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
            }
            .padding()
            .navigationTitle("Races")
        }
    }
}

#Preview {
    RacePrepView()
}
