import SwiftUI

struct LocationDetailScreen: View {

    @Environment(\.dismiss) private var dismiss
    @FocusState private var nicknameFocused: Bool

    let slot: String

    @State private var nickname = ""
    @State private var location: LocationPoint

    let onSave: (LocationPoint) -> Void
    private let nicknameLimit = 20

    init(
        slot: String,
        location: LocationPoint,
        onSave: @escaping (LocationPoint) -> Void
    ) {
        self.slot = slot
        _location = State(initialValue: location)
        self.onSave = onSave
    }

    var body: some View {

        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {

            SlotHeader(slot: slot, title: location.displayName)

            LabelValueRow(label: "aqi", value: "\(location.aqi)")

            Spacer()

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {

                TextField("Nick name", text: $nickname)
                    .focused($nicknameFocused)
                    .submitLabel(.done)
                    .onSubmit { nicknameFocused = false }
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surfaceMuted)
                    .cornerRadius(DesignTokens.Radius.card)
                    .onChange(of: nickname) { value in
                        if value.count > nicknameLimit {
                            nickname = String(value.prefix(nicknameLimit))
                        }
                    }
                    .accessibilityLabel("Nickname for slot \(slot)")
            }

            PrimaryButton(title: "Save") {
                location.nickname = nickname.isEmpty ? nil : nickname
                onSave(location)
                dismiss()
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            nickname = location.nickname ?? ""
            nicknameFocused = true
        }
    }
}
