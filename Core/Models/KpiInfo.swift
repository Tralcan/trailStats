import Foundation

/// Una estructura para contener la información de un KPI para mostrar en un popover informativo.
public struct KpiInfo: Identifiable {
    public let id: UUID
    public let title: String
    public let description: String

    public init(id: UUID = UUID(), title: String, description: String) {
        self.id = id
        self.title = title
        self.description = description
    }
}