import XCTest

/// Real iOS simulator taps. Does not claim co-op or 62s prologue support.
final class W3NewGameUITests: XCTestCase {
    func testDifficultyPlayersAndSafeCancel() {
        let app=XCUIApplication()
        XCUIDevice.shared.orientation = .landscapeRight
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"]="1"
        app.launch()
        let newGame=app.buttons["w3-home-0"]
        XCTAssertTrue(newGame.waitForExistence(timeout:30))
        newGame.tap()
        XCTAssertTrue(app.buttons["w3-new-start-source"].waitForExistence(timeout:12))
        app.buttons["w3-new-difficulty-0"].tap()
        app.buttons["w3-new-players-2"].tap()
        XCTAssertFalse(app.buttons["w3-new-start-source"].isEnabled)
        app.buttons["w3-new-players-1"].tap()
        XCTAssertTrue(app.buttons["w3-new-start-source"].isEnabled)
        // Never activate a potentially destructive new game in UI smoke.
        app.buttons["w3-panel-back"].tap()
        XCTAssertTrue(newGame.waitForExistence(timeout:12))
    }
}
