import XCTest

/// Genuine XCUITest on the installed iOS Simulator application.
/// Source-only contracts and an ARM64 xcodebuild do not prove that H290
/// actually opens. This test exercises the public W3 campaign route and
/// captures a real simulator framebuffer with the native Metal scene.
/// It does NOT certify on-device FPS, PC pixel parity, H55 proximity or IPA.
final class PC602HomeOrbitUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeRight
    }

    private func byID(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func require(_ element: XCUIElement, _ description: String,
                         timeout: TimeInterval = 30) {
        guard element.waitForExistence(timeout: timeout) else {
            XCTContext.runActivity(named: "Actual iOS simulator UI failure") { activity in
                let proof = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                proof.name = "PC602-H290-UI-Failure"
                proof.lifetime = .keepAlways
                activity.add(proof)
                print("PC602_ORBIT_UI_TREE_BEGIN")
                print(element.debugDescription)
                print("PC602_ORBIT_UI_TREE_END")
            }
            XCTFail(description)
            return
        }
    }

    func testRealCampaignToOrbitHUDAtlasAndReturn() {
        let app = XCUIApplication()
        // Existing W3 verification launch switch bypasses only the intro
        // gate. It does not replace H290, its resources or real flight.
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"] = "1"
        app.launch()

        let campaign = app.buttons["w3-home-2"]
        require(campaign, "Original W3 campaign entry missing", timeout: 90)
        campaign.tap()

        let enterOrbit = app.buttons["campaign-enter-original-orbit291"]
        require(enterOrbit, "Real PC602 H290 launch button missing")
        XCTAssertTrue(enterOrbit.isEnabled,
                      "Original H290 terrain/belt/ship source resources absent")
        enterOrbit.tap()

        let pause = app.buttons["pc602-orbit-pause"]
        require(pause, "Actual PC602 Metal gameplay HUD did not start",
                timeout: 90)
        require(byID(app, "pc602-orbit-live-touch-hud"),
                "Source H290 active touch HUD missing")
        XCTAssertFalse(byID(app, "pc602-orbit-return-w3").exists == false,
                       "Orbital W3 return control missing")

        // The captured image comes from THIS installed simulator build, not
        // a concept/mock-up or a screenshot of a different application.
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "Real-PC602-H290-Metal-Orbit-iOS-Simulator"
        capture.lifetime = .keepAlways
        add(capture)

        pause.tap()
        XCTAssertEqual(pause.label, "WZNÓW", "Pause did not freeze the game")
        pause.tap()
        XCTAssertEqual(pause.label, "PAUZA", "Game did not resume")

        let atlas = app.buttons["pc602-orbit-open-atlas330"]
        require(atlas, "Original 26-sector atlas action missing")
        atlas.tap()
        let first = app.buttons["pc602-orbit-sector-1"]
        require(first, "Original sector 01 is missing from orbit atlas")
        let close = app.buttons["pc602-orbit-close-atlas330"]
        require(close, "Atlas cannot return to live orbital flight")
        close.tap()
        require(atlas, "Closing source atlas did not restore orbital HUD")

        let back = app.buttons["pc602-orbit-return-w3"]
        require(back, "Orbit cannot return to original W3")
        back.tap()
        require(app.buttons["w3-home-2"],
                "Returning from H290 did not restore actual W3 menu")
    }
}
