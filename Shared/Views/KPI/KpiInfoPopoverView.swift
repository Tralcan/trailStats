import SwiftUI

struct KpiInfoPopoverView: View {
    let info: KPIInfo
    
    private var attributedDescription: AttributedString {
        do {
            // Attempt to initialize AttributedString from Markdown
            return try AttributedString(markdown: info.description, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            // If it fails, just return a plain AttributedString
            return AttributedString(info.description)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(info.title)
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView {
                Text(attributedDescription)
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