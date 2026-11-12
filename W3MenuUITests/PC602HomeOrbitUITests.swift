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
        // Screenshots inside the failure handler can hang a busy simulator,
        // hiding the original failure behind a second 60-second timeout.
        // Keep the failing step and its real identifier in the xcresult.
        XCTAssertTrue(element.waitForExistence(timeout: timeout),
                      description)
    }

    private func waitForActualW3Menu(_ app: XCUIApplication) {
        let campaign = app.buttons["w3-home-2"]
        // OriginalAudioAV568.prepareMenuAtStartup() synthesizes both
        // source menu tracks before it sets startupComplete. The original
        // 90-second generic UI timeout is NOT a source startup deadline.
        // Keep real audio preparation; never bypass it in gameplay code.
        for attempt in 1...6 {
            if campaign.waitForExistence(timeout: 60) { return }
            // Progress is recorded every minute without a potentially
            // blocking XCUIScreen screenshot or full hierarchy snapshot.
            let visible = app.staticTexts.allElementsBoundByIndex.prefix(12)
                .map { $0.label }
                .filter { !$0.isEmpty }
            print("PC602_W3_AUDIO_STARTUP_WAIT_\(attempt): \(visible)")
        }
        XCTFail("Original W3 campaign button missing after 360 seconds of " +
                "real source audio preparation; inspect logged loading " +
                "screen statuses and the simulator process logs")
    }

    func testRealCampaignToOrbitHUDAtlasAndReturn() {
        let app = XCUIApplication()
        // Existing W3 verification launch switch bypasses only the intro
        // gate. It does not replace H290, its resources or real flight.
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"] = "1"
        app.launch()

        waitForActualW3Menu(app)
        let campaign = app.buttons["w3-home-2"]
        require(campaign, "Original W3 campaign entry missing")
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
        require(app.buttons["pc602-orbit-enter-context"],
                "PC602 universal WEJDŹ control missing")
        // The captured image comes from THIS installed simulator build, not
        // a concept/mock-up or a screenshot of a different application.
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "Real-PC602-H290-Metal-Orbit-iOS-Simulator"
        capture.lifetime = .keepAlways
        add(capture)

        pause.tap()
        let pausePanel = byID(app, "pc602-orbit-pause-panel317")
        require(pausePanel, "PC602 W3 game-pause overlay did not open")
        let resume = app.buttons["pc602-orbit-pause-choice-0"]
        require(resume, "Original KONTYNUUJ action missing from pause")
        resume.tap()
        require(pause, "Game did not resume to live H290 HUD")
        XCTAssertEqual(pause.label, "PAUZA", "H290 remains paused")

        let atlas = app.buttons["pc602-orbit-open-atlas330"]
        require(atlas, "Original 26-sector atlas action missing")
        atlas.tap()
        let first = app.buttons["pc602-orbit-sector-1"]
        require(first, "Original sector 01 is missing from orbit atlas")
        let close = app.buttons["pc602-orbit-close-atlas330"]
        require(close, "Atlas cannot return to live orbital flight")
        close.tap()
        require(atlas, "Closing source atlas did not restore orbital HUD")

        let options = app.buttons["pc602-orbit-open-options291"]
        require(options, "Original OPCJE button missing from live orbit")
        options.tap()
        let back = app.buttons["pc602-orbit-return-w3"]
        require(back, "OPCJE cannot return to original W3")
        back.tap()
        require(app.buttons["w3-home-2"],
                "Returning from H290 did not restore actual W3 menu")
    }
}
