import SwiftUI
import UIKit

/// Utilidad para capturar una vista SwiftUI como imagen PNG
struct ViewSnapshotter {
    /// Captura la vista como PNG (sin compresión) para máxima fidelidad
    static func snapshot<V: View>(of view: V, size: CGSize, scale: CGFloat = UIScreen.main.scale) -> Data? {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        let renderer = UIGraphicsImageRenderer(size: size, format: UIGraphicsImageRendererFormat.default())
        let image = renderer.image { ctx in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        // Guardar como PNG (sin compresión)
        return image.pngData()
    }
}
