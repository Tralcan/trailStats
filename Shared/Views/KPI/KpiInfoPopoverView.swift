
import SwiftUI

struct KpiInfoPopoverView: View {
    let info: KPIInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(info.title)
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView {
                Text(info.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 20)
        .padding()
    }
}
