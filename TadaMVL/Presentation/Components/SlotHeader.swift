import SwiftUI

struct SlotHeader: View {

    let slot: String
    let title: String
    var titleColor: Color = DesignTokens.Colors.textPrimary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.md) {
            Text(slot)
                .font(.title2.weight(.bold))
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(minWidth: 18, alignment: .leading)

            Text(title)
                .font(DesignTokens.Typography.heading)
                .foregroundColor(titleColor)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(slot) \(title)")
    }
}
