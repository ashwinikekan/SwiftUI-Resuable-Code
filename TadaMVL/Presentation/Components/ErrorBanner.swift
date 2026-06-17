import SwiftUI

struct ErrorBanner: View {

    let message: String
    var autoDismissAfter: TimeInterval = 3
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(DesignTokens.Colors.danger)
            Text(message)
                .font(DesignTokens.Typography.label)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .lineLimit(2)

            Spacer(minLength: DesignTokens.Spacing.sm)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .padding(6)
            }
            .accessibilityLabel("Dismiss error")
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.Radius.card)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .task {
            try? await Task.sleep(nanoseconds: UInt64(autoDismissAfter * 1_000_000_000))
            onDismiss()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}
