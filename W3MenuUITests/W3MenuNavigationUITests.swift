import XCTest

/// True UI automation: taps each original source-v568 W3 button on the
/// actual installed app. This does NOT pretend that mission loading,
/// save-game restore or a hangar is already implemented.
final class W3MenuNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Real native accessibility, not a simulated menu or a fake test-mode
    /// hierarchy. Both a Button and an accessible other element can be
    /// tapped; missing control logs the real on-device XCUI hierarchy.
    private func menuButton(_ app: XCUIApplication, index: Int) -> XCUIElement {
        let identifier = "w3-home-\(index)"
        let button = app.buttons[identifier]
        if button.waitForExistence(timeout: 10) { return button }
        let visible = app.descendants(matching: .any)
            .matching(identifier: identifier).firstMatch
        if visible.waitForExistence(timeout: 5) { return visible }
        XCTContext.runActivity(named: "Actual W3 iOS accessibility hierarchy") { activity in
            print("W3_ACTUAL_ACCESSIBILITY_TREE_BEGIN")
            print(app.debugDescription)
            print("W3_ACTUAL_ACCESSIBILITY_TREE_END")
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Actual-W3-Simulator-UI-On-Failure"
            screenshot.lifetime = .keepAlways
            activity.add(screenshot)
        }
        XCTFail("Original v568 native W3 menu button \(identifier) was not exposed to XCTest")
        return button
    }

    private func launchW3() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"] = "1"
        // No changes to app data, original mission selection or graphics.
        // The original app supports only landscape orientations.
        // Align XCTest's device frame with the actual on-screen layout.
        XCUIDevice.shared.orientation = .landscapeRight
        app.launch()
        _ = menuButton(app,index:0)
        return app
    }

    func testSevenOriginalMenuActionsAndBack() {
        let app=launchW3()
        for index in 0..<7 {
            let button=menuButton(app,index:index)
            XCTAssertTrue(button.waitForExistence(timeout: 10),
                          "Missing original W3 menu action \(index)")
            button.tap()
            let back=app.buttons["w3-panel-back"]
            XCTAssertTrue(back.waitForExistence(timeout: 15),
                          "W3 panel \(index) did not open")
            // The atlas provides actual source-locked sector selection;
            // only source C279 planet inspection is open, not combat.
            if index==0 || index==2 {
                XCTAssertTrue(
                    app.staticTexts["ATLAS 26 SEKTORÓW — WYBÓR I WEJŚCIE NA CARBONIS"]
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
        XCTAssertTrue(menuButton(app,index:0).waitForExistence(timeout: 20),
                      "Returning from 3D diagnostic must show actual W3 menu")
        XCTAssertFalse(app.buttons["w3-panel-back"].exists)
    }
}
