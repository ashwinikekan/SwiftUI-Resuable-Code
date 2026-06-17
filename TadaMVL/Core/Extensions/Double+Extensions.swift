import Foundation

extension Double {

    func truncatedTo3() -> Double {
        (self * 1000).rounded(.towardZero) / 1000
    }
}
