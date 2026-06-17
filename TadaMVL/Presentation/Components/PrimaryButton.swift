import SwiftUI

struct PrimaryButton: View {

    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.value)
                .foregroundColor(DesignTokens.Colors.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.lg)
                .background(
                    DesignTokens.Colors.primary
                        .opacity(isEnabled ? 1.0 : 0.4)
                )
                .cornerRadius(DesignTokens.Radius.card)
        }
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }
}
