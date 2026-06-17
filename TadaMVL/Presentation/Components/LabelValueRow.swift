import SwiftUI

struct LabelValueRow: View {

    let label: String
    let value: String
    var valueColor: Color = DesignTokens.Colors.textPrimary

    var body: some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.label)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignTokens.Typography.value)
                .foregroundColor(valueColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }
}
