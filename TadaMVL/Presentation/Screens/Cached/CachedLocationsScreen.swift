import SwiftUI

// 5th screen: pick a cached location to assign to A or B.
// Intentionally minimal - just the alphabetical avatar + display name.
struct CachedLocationsScreen: View {

    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss

    let onSelect: (LocationPoint) -> Void

    @State private var locations: [LocationPoint] = []

    var body: some View {
        Group {
            if locations.isEmpty {
                emptyState
            } else {
                listView
            }
        }
        .background(DesignTokens.Colors.surface.ignoresSafeArea())
       // .navigationTitle("Cached Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") { dismiss() }
            }
        }
        .onAppear {
            // Snapshot on appear is fine - users can't add new locations
            // without dismissing this sheet first.
            locations = container.cache.allLocations()
        }
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(locations.enumerated()), id: \.element.id) { index, location in
                    Button {
                        onSelect(location)
                        dismiss()
                    } label: {
                        SlotHeader(slot: letter(for: index), title: location.displayName)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < locations.count - 1 {
                        Divider()
                            .background(DesignTokens.Colors.divider)
                            .padding(.horizontal, DesignTokens.Spacing.lg)
                    }
                }
            }
            .padding(.top, DesignTokens.Spacing.md)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            Text("No cached locations yet")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("No cached locations yet")
    }

    // 0 -> "A", 1 -> "B", ... 25 -> "Z". Past 26 we just show the index.
    // In practice nobody will see "27" - the cache won't realistically
    // grow that big in a demo - but degrade gracefully anyway.
    private func letter(for index: Int) -> String {
        guard index < 26 else { return "\(index + 1)" }
        return String(Character(UnicodeScalar(65 + index)!))
    }
}
