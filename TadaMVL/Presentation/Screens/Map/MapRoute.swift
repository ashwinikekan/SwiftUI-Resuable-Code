import Foundation

enum MapRoute: Hashable {
    case detail(slot: String, location: LocationPoint)
    case booking
    case history
}
