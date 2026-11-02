import XCTest

final class LexcopeUITests: XCTestCase {
    func testStudyGesturesDetailsAudioAndPersistence() throws {
        let app = XCUIApplication()
        app.launchEnvironment["LEXCOPE_UI_TEST_SESSION"] = UUID().uuidString
        app.launch()
        app.tabBars.buttons["词集"].tap()
        let deck = app.buttons["select-deck-ngsl-starter"]
        XCTAssertTrue(deck.waitForExistence(timeout: 10))
        deck.tap()
        app.tabBars.buttons["今日"].tap()
        app.buttons["start-study"].tap()
        let help = app.buttons["dismiss-study-help"]
        if help.waitForExistence(timeout: 3) { help.tap() }

        let word = app.buttons["study-word"]
        XCTAssertTrue(word.waitForExistence(timeout: 5))
        XCTAssertEqual(word.label, "remember")
        app.buttons["study-pronunciation"].tap()
        XCTAssertTrue(word.exists, "Pronunciation must leave the card visible")
        XCTAssertFalse(app.navigationBars["单词详情"].exists)
        word.tap()
        XCTAssertTrue(app.navigationBars["单词详情"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["记得；记住"].exists)
        app.buttons["close-details"].tap()

        drag(app, dx: 160, dy: 0)
        XCTAssertTrue(waitForLabel(word, "opportunity"))
        app.buttons["undo-rating"].tap()
        XCTAssertTrue(waitForLabel(word, "remember"))
        drag(app, dx: -160, dy: 0)
        XCTAssertTrue(waitForLabel(word, "opportunity"))
        drag(app, dx: 0, dy: 150)
        XCTAssertTrue(waitForLabel(word, "available"))

        app.terminate()
        app.launch()
        app.buttons["start-study"].tap()
        XCTAssertTrue(word.waitForExistence(timeout: 5))
        XCTAssertEqual(word.label, "available", "Restart must retain ratings and deck selection")
    }

    private func waitForLabel(_ element: XCUIElement, _ label: String) -> Bool {
        XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: element)], timeout: 5) == .completed
    }

    private func drag(_ app: XCUIApplication, dx: CGFloat, dy: CGFloat) {
        // Start below the text/IPA buttons, on the card background.
        let card = app.otherElements["study-card"]
        let start = card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let end = start.withOffset(CGVector(dx: dx, dy: dy))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
