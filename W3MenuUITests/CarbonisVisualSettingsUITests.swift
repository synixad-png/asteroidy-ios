import XCTest

/// Real simulator taps on original v568 visual settings; not a simulated UI.
/// Uses the existing W3 menu and genuine persistent UserDefaults state.
final class CarbonisVisualSettingsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure=false }

    private func touch(_ e:XCUIElement,app:XCUIApplication,scrollID:String) {
        XCTAssertTrue(e.waitForExistence(timeout:15),"Original W3 control missing")
        let identified=app.scrollViews[scrollID]
        let scroll=identified.exists ? identified : app.scrollViews.firstMatch
        let isCategory=e.identifier.hasPrefix("w3-effects-tab-")
        let rail=app.scrollViews["w3-effects-tabs-524-285"]
        for _ in 0..<12 {
            if e.isHittable {break}
            if isCategory && rail.exists {
                // Real W3 source order: AUDIO=1, PLANETY=7,
                // EXPLOSIONS=11, STATEK=13, POCISKI=16.
                if e.identifier=="w3-effects-tab-2"
                   || e.identifier=="w3-effects-tab-3" {
                    rail.swipeDown()
                } else {
                    rail.swipeUp()
                }
            } else if scroll.exists {
                scroll.swipeUp()
            }
        }
        if !e.isHittable {print("W3_FX_UI_TREE:\n",app.debugDescription)}
        XCTAssertTrue(e.isHittable,"Original W3 control is not touchable")
        e.tap()
    }

    private func enterSettings(_ app:XCUIApplication) {
        touch(app.buttons["w3-home-4"],app:app,
              scrollID:"w3-home-navigation")
        XCTAssertTrue(app.buttons["w3-panel-back"]
            .waitForExistence(timeout:15))
        XCTAssertTrue(app.buttons["w3-effects-tab-0"]
            .waitForExistence(timeout:10))
        XCTAssertTrue(app.buttons["w3-effects-tab-1"].exists)
    }

    func testSourceMusicLibraryStopReplayAndPersistence() {
        let app=XCUIApplication()
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"]="1"
        XCUIDevice.shared.orientation = .landscapeRight
        app.launch()
        enterSettings(app)
        touch(app.buttons["w3-effects-tab-2"],app:app,
              scrollID:"w3-effects-scroll")
        let music=app.sliders["w3-music-volume-8"]
        let effects=app.sliders["w3-effects-volume-9"]
        XCTAssertTrue(music.waitForExistence(timeout:15))
        XCTAssertTrue(effects.waitForExistence(timeout:15))
        music.adjust(toNormalizedSliderPosition:1)
        effects.adjust(toNormalizedSliderPosition:1)
        touch(app.buttons["w3-audio-stop-355"],app:app,
              scrollID:"w3-effects-scroll")
        touch(app.buttons["w3-audio-replay-355"],app:app,
              scrollID:"w3-effects-scroll")
        // Source W3 Music355 CloseMusic restores Menu track 0.
        touch(app.buttons["w3-panel-back"],app:app,
              scrollID:"w3-effects-scroll")
        XCTAssertTrue(app.buttons["w3-home-4"].waitForExistence(timeout:10))
        app.terminate()
        app.launch()
        enterSettings(app)
        touch(app.buttons["w3-effects-tab-2"],app:app,
              scrollID:"w3-effects-scroll")
        let restoredMusic=app.sliders["w3-music-volume-8"]
        let restoredEffects=app.sliders["w3-effects-volume-9"]
        XCTAssertTrue(restoredMusic.waitForExistence(timeout:15))
        XCTAssertTrue(restoredEffects.waitForExistence(timeout:15))
        XCTAssertEqual(restoredMusic.value as? String,"100%")
        XCTAssertEqual(restoredEffects.value as? String,"100%")
    }

    func testVisualSettingsPersistAfterProcessRelaunch() {
        let app=XCUIApplication()
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"]="1"
        XCUIDevice.shared.orientation = .landscapeRight
        app.launch()
        enterSettings(app)

        touch(app.buttons["w3-explosion-type-1"],app:app,
              scrollID:"w3-effects-scroll")
        XCTAssertEqual(app.staticTexts["w3-explosion-value-0"].label,"92%")
        XCTAssertEqual(app.staticTexts["w3-explosion-value-1"].label,"11")
        let quality=app.buttons["w3-explosion-quality-1"]
        touch(quality,app:app,scrollID:"w3-effects-scroll")
        XCTAssertEqual(quality.value as? String,"wybrany")

        touch(app.buttons["w3-effects-tab-1"],app:app,
              scrollID:"w3-effects-scroll")
        let brightness=app.sliders["w3-projectile-light-brightness"]
        XCTAssertTrue(brightness.waitForExistence(timeout:10))
        brightness.adjust(toNormalizedSliderPosition:0)
        XCTAssertEqual(app.staticTexts["w3-projectile-brightness-value"].label,"0%")
        brightness.adjust(toNormalizedSliderPosition:1)
        XCTAssertEqual(app.staticTexts["w3-projectile-brightness-value"].label,"400%")
        XCTAssertTrue(app.buttons["w3-projectile-light-color"]
            .waitForExistence(timeout:10),"Eight-color picker must exist")
        let toggle=app.switches["w3-projectile-light-mixed"]
        XCTAssertTrue(toggle.waitForExistence(timeout:10))
        let before=toggle.value as? String
        touch(toggle,app:app,scrollID:"w3-effects-scroll")
        let after=toggle.value as? String
        XCTAssertNotEqual(before,after)

        touch(app.buttons["w3-panel-back"],app:app,
              scrollID:"w3-effects-scroll")
        app.terminate()
        app.launch()
        enterSettings(app)
        XCTAssertEqual(app.staticTexts["w3-explosion-value-0"].label,"92%")
        XCTAssertEqual(app.staticTexts["w3-explosion-value-1"].label,"11")
        XCTAssertEqual(app.buttons["w3-explosion-quality-1"].value as? String,
                       "wybrany")
        touch(app.buttons["w3-effects-tab-1"],app:app,
              scrollID:"w3-effects-scroll")
        XCTAssertEqual(app.staticTexts["w3-projectile-brightness-value"].label,
                       "400%")
        let restored=app.switches["w3-projectile-light-mixed"]
        XCTAssertTrue(restored.waitForExistence(timeout:10))
        XCTAssertEqual(restored.value as? String,after)
        touch(app.buttons["w3-panel-back"],app:app,
              scrollID:"w3-effects-scroll")
        XCTAssertTrue(app.buttons["w3-home-4"].waitForExistence(timeout:10))
    }
    /// Original Menu139 STATEK #100/#101: separate 70..150% visual scales.
    /// Both values must persist across a real iOS process restart.
    func testSourceShipMissionAndOrbitScalesPersist() {
        let app=XCUIApplication()
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"]="1"
        XCUIDevice.shared.orientation = .landscapeRight
        func openShipTab() {
            enterSettings(app)
            let strip=app.scrollViews["w3-effects-tabs-524-285"]
            let statek=app.buttons["w3-effects-tab-5"]
            XCTAssertTrue(statek.waitForExistence(timeout:10),
                          "Original source STATEK tab must exist")
            for _ in 0..<12 where !statek.isHittable {
                if strip.exists { strip.swipeUp() }
            }
            XCTAssertTrue(statek.isHittable,
                          "Original source STATEK tab must be touchable")
            statek.tap()
            XCTAssertTrue(app.sliders["w3-ship-mission-scale-slider-472"]
                .waitForExistence(timeout:10))
        }
        app.launch()
        openShipTab()
        let mission=app.sliders["w3-ship-mission-scale-slider-472"]
        let orbit=app.sliders["w3-ship-orbit-scale-slider-472"]
        XCTAssertTrue(orbit.waitForExistence(timeout:10))
        mission.adjust(toNormalizedSliderPosition:0)
        orbit.adjust(toNormalizedSliderPosition:1)
        XCTAssertEqual(app.staticTexts["w3-ship-mission-scale-value-472"].label,"70%")
        XCTAssertEqual(app.staticTexts["w3-ship-orbit-scale-value-472"].label,"150%")
        touch(app.buttons["w3-panel-back"],app:app,
              scrollID:"w3-effects-scroll")
        app.terminate()
        app.launch()
        openShipTab()
        XCTAssertEqual(app.staticTexts["w3-ship-mission-scale-value-472"].label,"70%")
        XCTAssertEqual(app.staticTexts["w3-ship-orbit-scale-value-472"].label,"150%")
    }

}
