import Foundation

struct Book: Codable, Identifiable {
    let id: UUID
    let a: LocationPoint
    let b: LocationPoint
    let price: Double
}
