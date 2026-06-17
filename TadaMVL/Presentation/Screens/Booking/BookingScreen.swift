import SwiftUI

struct BookingScreen: View {

    @EnvironmentObject private var container: AppContainer

    let a: LocationPoint
    let b: LocationPoint

    @Binding var path: [MapRoute]
    let onBack: () -> Void

    @StateObject private var viewModel: BookingViewModel

    init(
        container: AppContainer,
        a: LocationPoint,
        b: LocationPoint,
        path: Binding<[MapRoute]>,
        onBack: @escaping () -> Void
    ) {
        self.a = a
        self.b = b
        self._path = path
        self.onBack = onBack
        _viewModel = StateObject(
            wrappedValue: BookingViewModel(createBookUseCase: container.createBookUseCase)
        )
    }

    var body: some View {

        VStack(spacing: DesignTokens.Spacing.xl) {

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {

                    if let book = viewModel.state.book {
                        slotSection(slot: "A", location: book.a)
                        slotSection(slot: "B", location: book.b)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, DesignTokens.Spacing.xxl)
                    }
                }
                .padding(.top, DesignTokens.Spacing.md)
            }
            
            if let book = viewModel.state.book {
                  LabelValueRow(
                      label: "price",
                      value: "\(Int(book.price))"
                  )
              }

            PrimaryButton(title: "Book", isEnabled: viewModel.state.book != nil) {
                path.append(.history)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") { onBack() }
            }
        }
        .task {
            viewModel.send(.create(a: a, b: b))
        }
    }

    private func slotSection(slot: String, location: LocationPoint) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            SlotHeader(slot: slot, title: location.displayName)
            LabelValueRow(label: "aqi", value: "\(location.aqi)")
            LabelValueRow(
                label: "Nick name",
                value: location.nickname?.isEmpty == false ? location.nickname! : "—",
                valueColor: location.nickname?.isEmpty == false
                    ? DesignTokens.Colors.textPrimary
                    : DesignTokens.Colors.textSecondary
            )
        }
    }
}
