import Foundation

// Drives the title of the bottom-right V button.
enum BookingStep {
    case setA
    case setB
    case book

    var buttonTitle: String {
        switch self {
        case .setA: return "Set A"
        case .setB: return "Set B"
        case .book: return "Book"
        }
    }
}
