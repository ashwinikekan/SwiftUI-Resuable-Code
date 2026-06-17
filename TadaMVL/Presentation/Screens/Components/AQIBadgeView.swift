import SwiftUI

// Top-right AQI pill from the mockup: muted "aqi" label + bold value.
struct AQIBadgeView: View {

    let aqi: Int

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Text("aqi")
                .font(DesignTokens.Typography.label)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            Text("\(aqi)")
                .font(DesignTokens.Typography.value)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.Radius.card)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Air quality \(aqi)")
    }
}
