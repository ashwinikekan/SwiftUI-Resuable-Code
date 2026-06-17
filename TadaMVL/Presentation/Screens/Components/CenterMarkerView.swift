import SwiftUI

// Black teardrop pin sitting at the map center. Built as a circle "head"
struct CenterMarkerView: View {

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(DesignTokens.Colors.textPrimary)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .fill(DesignTokens.Colors.surface)
                        .frame(width: 8, height: 8)
                )
            Triangle()
                .fill(DesignTokens.Colors.textPrimary)
                .frame(width: 14, height: 14)
                .offset(y: -2) // close the seam between head and tail
        }
        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
        .accessibilityHidden(true)
        // Nudge the whole pin up so the visual point lands on the map
        // center, not the head center.
        .offset(y: -10)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
