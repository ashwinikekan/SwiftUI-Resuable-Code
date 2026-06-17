import Testing
import SwiftUI
import UIKit
import Foundation
@testable import TadaMVL


@Suite(.serialized)
@MainActor
struct ViewSmokeTests {

    @Test
    func errorBanner_rendersWithoutCrashing() {
        mount(ErrorBanner(message: "Something went wrong", onDismiss: {}))
    }

    @Test
    func primaryButton_rendersBothEnabledAndDisabled() {
        mount(PrimaryButton(title: "Save", isEnabled: true, action: {}))
        mount(PrimaryButton(title: "Save", isEnabled: false, action: {}))
    }

    @Test
    func slotHeader_rendersWithCustomColor() {
        mount(SlotHeader(slot: "A", title: "Seoul, Gangnam-gu"))
        mount(SlotHeader(
            slot: "B",
            title: "Mumbai, Bandra",
            titleColor: DesignTokens.Colors.textSecondary
        ))
    }

    @Test
    func labelValueRow_rendersBothColorVariants() {
        mount(LabelValueRow(label: "aqi", value: "42"))
        mount(LabelValueRow(
            label: "nickname",
            value: "—",
            valueColor: DesignTokens.Colors.textSecondary
        ))
    }

    @Test
    func aqiBadge_rendersWithZero_andLargeValue() {
        mount(AQIBadgeView(aqi: 0))
        mount(AQIBadgeView(aqi: 999))
    }

    @Test
    func centerMarker_rendersWithoutCrashing() {
        mount(CenterMarkerView())
    }

    @Test
    func historyRow_rendersWithSampleBook() {
        let book = sampleBook()
        mount(HistoryRowView(book: book))
    }

    @Test
    func bottomActionView_rendersAllSlotConfigurations() {
        // both empty
        mount(BottomActionView(
            locationA: nil, locationB: nil, buttonTitle: "Set A",
            onALocationTap: {}, onBLocationTap: {}, onButtonTap: {}
        ))
        // a set, b empty
        mount(BottomActionView(
            locationA: samplePoint(name: "Home"), locationB: nil, buttonTitle: "Set B",
            onALocationTap: {}, onBLocationTap: {}, onButtonTap: {}
        ))
        // both set
        mount(BottomActionView(
            locationA: samplePoint(name: "Home"),
            locationB: samplePoint(name: "Office"),
            buttonTitle: "Book",
            onALocationTap: {}, onBLocationTap: {}, onButtonTap: {}
        ))
    }

    @Test
    func locationDetail_rendersWithAndWithoutNickname() {
        mount(LocationDetailScreen(
            slot: "A",
            location: samplePoint(name: "Seoul, Gangnam-gu", nickname: nil),
            onSave: { _ in }
        ))
        mount(LocationDetailScreen(
            slot: "B",
            location: samplePoint(name: "Seoul, Jongno-gu", nickname: "office"),
            onSave: { _ in }
        ))
    }

    @Test
    func bookingScreen_rendersInitialState() {
        let container = AppContainer()
        var path: [MapRoute] = []
        let binding = Binding(get: { path }, set: { path = $0 })

        let screen = BookingScreen(
            container: container,
            a: samplePoint(name: "A"),
            b: samplePoint(name: "B"),
            path: binding,
            onBack: {}
        )
        .environmentObject(container)
        mount(screen)
    }

    @Test
    func historyScreen_rendersEmptyAndLoadingStates() {
        let container = AppContainer()
        let screen = HistoryScreen(
            container: container,
            onRowTap: { _ in },
            onClose: {}
        )
        .environmentObject(container)
        mount(screen)
    }

    @Test
    func cachedLocationsScreen_rendersEmptyState() {
        let container = AppContainer()
        let screen = CachedLocationsScreen(onSelect: { _ in })
            .environmentObject(container)
        mount(screen)
    }

    @Test
    func mapScreen_rendersBootstrap() {
        let container = AppContainer()
        mount(MapScreen(container: container).environmentObject(container))
    }

    // MARK: helpers

    private func mount<V: View>(_ view: V) {
        // UIHostingController forces a real layout pass, which evaluates
        // `body` and any `@ViewBuilder` switches. We size it to a phone
        // viewport so adaptive code paths fire.
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        host.view.layoutIfNeeded()
    }

    private func samplePoint(name: String, nickname: String? = nil) -> LocationPoint {
        LocationPoint(
            id: UUID(),
            latitude: 37.5665,
            longitude: 126.9780,
            aqi: 42,
            address: name,
            nickname: nickname
        )
    }

    private func sampleBook() -> Book {
        Book(
            id: UUID(),
            a: samplePoint(name: "Seoul, Gangnam-gu"),
            b: samplePoint(name: "Seoul, Jongno-gu", nickname: "office"),
            price: 10_000
        )
    }
}
