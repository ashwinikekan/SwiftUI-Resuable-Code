import Foundation

// Wire-level types for /books. Kept separate from the domain model so the
// network contract can change without dragging changes into Book / LocationPoint.

struct BookLocationDTO: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let aqi: Int
    let name: String
}

struct BookRequestDTO: Codable, Equatable {
    let a: BookLocationDTO
    let b: BookLocationDTO
}

struct BookResponseDTO: Codable, Equatable {
    // Optional because the brief's example response doesn't include it.
    // Real backends usually do.
    let id: String?
    let a: BookLocationDTO
    let b: BookLocationDTO
    let price: Double
}

// MARK: Domain <-> DTO mapping

extension LocationPoint {

    // displayName picks nickname over address, which is what we want the
    // backend to see as the human label.
    var bookingDTO: BookLocationDTO {
        BookLocationDTO(
            latitude: latitude,
            longitude: longitude,
            aqi: aqi,
            name: displayName
        )
    }

    // Reverse mapping is lossy: the wire has one `name` field, so we put
    // it into `address` and leave `nickname` nil. `displayName` still
    // returns something sensible.
    init(dto: BookLocationDTO) {
        self.init(
            id: UUID(),
            latitude: dto.latitude,
            longitude: dto.longitude,
            aqi: dto.aqi,
            address: dto.name,
            nickname: nil
        )
    }
}

extension Book {
    init(dto: BookResponseDTO) {
        self.init(
            id: dto.id.flatMap(UUID.init(uuidString:)) ?? UUID(),
            a: LocationPoint(dto: dto.a),
            b: LocationPoint(dto: dto.b),
            price: dto.price
        )
    }
}
