import SwiftUI

struct AddCommentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var comment: String = ""
    
    var onSave: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Añadir Comentario")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextEditor(text: $comment)
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                
                Button(action: {
                    onSave(comment)
                    dismiss()
                }) {
                    Text("Guardar Comentario")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(comment.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Cancelar") { dismiss() })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}