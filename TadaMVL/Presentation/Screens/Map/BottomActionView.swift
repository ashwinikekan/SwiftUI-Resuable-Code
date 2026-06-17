import SwiftUI

// Bottom panel on the map screen. Two stacked rows on the left (A then B)
// and a square yellow primary button on the right that cycles its title
// through "Set A" -> "Set B" -> "Book".
struct BottomActionView: View {

    let locationA: LocationPoint?
    let locationB: LocationPoint?
    let buttonTitle: String

    let onALocationTap: () -> Void
    let onBLocationTap: () -> Void
    let onButtonTap: () -> Void

    private let buttonSide: CGFloat = 88

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignTokens.Colors.divider)
                .frame(height: 1)

            HStack(spacing: DesignTokens.Spacing.md) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    slotRow(slot: "A", point: locationA, onTap: onALocationTap)
                    slotRow(slot: "B", point: locationB, onTap: onBLocationTap)
                }

                Button(action: onButtonTap) {
                    Text(buttonTitle)
                        .font(DesignTokens.Typography.value)
                        .foregroundColor(DesignTokens.Colors.onPrimary)
                        .frame(width: buttonSide, height: buttonSide)
                        .background(DesignTokens.Colors.primary)
                        .cornerRadius(DesignTokens.Radius.card)
                }
                .accessibilityLabel(buttonTitle)
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .background(DesignTokens.Colors.surface)
    }

    private func slotRow(
        slot: String,
        point: LocationPoint?,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack {
                Text(slot)
                    .font(DesignTokens.Typography.value)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Spacer()

                Text(point?.displayName ?? "location name")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(
                        point == nil
                            ? DesignTokens.Colors.textSecondary
                            : DesignTokens.Colors.textPrimary
                    )
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(DesignTokens.Colors.surfaceMuted)
            .cornerRadius(DesignTokens.Radius.card)
        }
        .accessibilityLabel("\(slot) \(point?.displayName ?? "location name")")
    }
}
