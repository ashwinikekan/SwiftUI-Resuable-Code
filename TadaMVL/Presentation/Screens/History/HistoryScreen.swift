import SwiftUI

struct HistoryScreen: View {

    @EnvironmentObject private var container: AppContainer

    let onRowTap: (Book) -> Void
    let onClose: () -> Void

    @StateObject private var viewModel: HistoryViewModel

    init(
        container: AppContainer,
        onRowTap: @escaping (Book) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.onRowTap = onRowTap
        self.onClose = onClose
        _viewModel = StateObject(
            wrappedValue: HistoryViewModel(fetchBooksUseCase: container.fetchBooksUseCase)
        )
    }

    var body: some View {

        VStack(spacing: 0) {
            summaryHeader

            Divider()
                .background(DesignTokens.Colors.divider)

            if viewModel.state.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.state.books.isEmpty {
                emptyState
            } else {
                booksList
            }
        }
        .background(DesignTokens.Colors.surface.ignoresSafeArea())
       // .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { onClose() }
            }
        }
        .task {
            viewModel.send(.load)
        }
    }
}

private extension HistoryScreen {
  
    var summaryHeader: some View {
        HStack(spacing: 0) {
            summaryCell(
                label: "Total Count",
                value: "\(viewModel.state.totalRecords)"
            )

            Rectangle()
                .fill(DesignTokens.Colors.divider)
                .frame(width: 1, height: 60)

            summaryCell(
                label: "Total Price",
                value: "\(Int(viewModel.state.totalPrice))"
            )
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    func summaryCell(label: String, value: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(label)
                .font(DesignTokens.Typography.label)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }

    var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            Text("No bookings this month")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("No bookings this month")
    }

    var booksList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.state.books.enumerated()), id: \.element.id) { index, book in
                    Button {
                        onRowTap(book)
                    } label: {
                        HistoryRowView(book: book)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                    if index < viewModel.state.books.count - 1 {
                        Divider()
                            .background(DesignTokens.Colors.divider)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                    }
                }
            }
        }
    }
}
