import SwiftUI

// Single history row: stacked A and B headers. The total price lives in
struct HistoryRowView: View {

    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            SlotHeader(slot: "A", title: book.a.displayName)
            SlotHeader(slot: "B", title: book.b.displayName)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Booking: A \(book.a.displayName), B \(book.b.displayName)")
    }
}
