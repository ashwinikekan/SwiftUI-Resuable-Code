import Testing
@testable import TadaMVL

@MainActor
struct BookingStepTests {

    @Test
    func buttonTitles() {
        #expect(BookingStep.setA.buttonTitle == "Set A")
        #expect(BookingStep.setB.buttonTitle == "Set B")
        #expect(BookingStep.book.buttonTitle == "Book")
    }
}
