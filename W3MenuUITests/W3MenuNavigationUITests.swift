import XCTest

/// True UI automation: taps each original source-v568 W3 button on the
/// actual installed app. This does NOT pretend that mission loading,
/// save-game restore or a hangar is already implemented.
final class W3MenuNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchW3() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"] = "1"
        app.launch()
        XCTAssertTrue(
            app.buttons["w3-home-0"].waitForExistence(timeout: 25),
            "Native W3 menu must be the normal launch screen")
        return app
    }

    func testSevenOriginalMenuActionsAndBack() {
        let app=launchW3()
        for index in 0..<7 {
            let button=app.buttons["w3-home-\(index)"]
            XCTAssertTrue(button.waitForExistence(timeout: 10),
                          "Missing original W3 menu action \(index)")
            button.tap()
            let back=app.buttons["w3-panel-back"]
            XCTAssertTrue(back.waitForExistence(timeout: 15),
                          "W3 panel \(index) did not open")
            // The UI presents the actual read-only mission atlas for
            // Nowa Gra/Kampania, NOT a fictitious playable 26-sector map.
            if index==0 || index==2 {
                XCTAssertTrue(
                    app.staticTexts["ATLAS 26 SEKTORÓW — PODGLĄD, BEZ URUCHAMIANIA MISJI"]
                        .waitForExistence(timeout: 8),
                    "Mission atlas must say it is a read-only preview")
            }
            back.tap()
            XCTAssertTrue(button.waitForExistence(timeout: 10),
                          "Cannot navigate back to W3 menu from item \(index)")
            XCTAssertFalse(app.buttons["w3-panel-back"].exists,
                           "Modal panel must be dismissed before next action")
        }
    }

    func testDiagnosticSceneAndReturnToRealMenu() {
        let app=launchW3()
        let diagnostic=app.buttons["w3-open-diagnostic"]
        XCTAssertTrue(diagnostic.waitForExistence(timeout: 12))
        diagnostic.tap()
        let returnButton=app.buttons["MENU W3"]
        XCTAssertTrue(returnButton.waitForExistence(timeout: 20),
                      "Source-diagnostic scene must offer MENU W3 return")
        returnButton.tap()
        XCTAssertTrue(app.buttons["w3-home-0"].waitForExistence(timeout: 20),
                      "Returning from 3D diagnostic must show actual W3 menu")
        XCTAssertFalse(app.buttons["w3-panel-back"].exists)
    }
}
