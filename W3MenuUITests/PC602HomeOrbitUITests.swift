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
        let pausePanel = byID(app, "pc602-orbit-options291")
        require(pausePanel, "Shared H290 PAUZA panel did not open")
        let resume = app.buttons["pc602-orbit-options-back"]
        require(resume, "KONTYNUUJ missing from the only H290 pause panel")
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

        // O09: the SAME PAUZA panel opens the actual three-slot model.
        pause.tap()
        let saveFromPause = app.buttons["pc602-orbit-save61"]
        require(saveFromPause, "PAUZA -> ZAPISZ LOT missing")
        saveFromPause.tap()
        require(app.buttons["pc602-save61-action-0"],
                "Original SaveManager61 ZAPISZ missing")
        require(app.buttons["pc602-save61-action-1"],
                "Original SaveManager61 WCZYTAJ missing")
        require(app.buttons["pc602-save61-action-2"],
                "Original SaveManager61 USUŃ missing")
        let saveBack = app.buttons["pc602-save61-back"]
        require(saveBack, "No return from original save slots")
        saveBack.tap()
        // Same as CARBONIS 01: dismissing slots returns to PAUZA.
        let resumeAfterSlots = app.buttons["pc602-orbit-options-back"]
        require(resumeAfterSlots, "No PAUZA after returning from slots")
        resumeAfterSlots.tap()

        let options = app.buttons["pc602-orbit-open-options291"]
        require(options, "Single PAUZA button missing from live orbit")
        options.tap()
        let back = app.buttons["pc602-orbit-return-w3"]
        require(back, "OPCJE cannot return to original W3")
        back.tap()
        require(app.buttons["w3-home-2"],
                "Returning from H290 did not restore actual W3 menu")

        // O09: manual W3 slots are real even without an existing saved run.
        let continuePage = app.buttons["w3-home-1"]
        require(continuePage, "W3 KONTYNUJ action missing")
        continuePage.tap()
        let manualSlots = app.buttons["w3-manual-slots61"]
        require(manualSlots, "W3 manual 3-slot selector missing")
        manualSlots.tap()
        let delete = app.buttons["pc602-save61-action-2"]
        require(delete, "Original delete slot action missing")
        let disabledSave = app.buttons["pc602-save61-action-0"]
        require(disabledSave, "Source menu slot action missing")
        XCTAssertFalse(disabledSave.isEnabled,
                       "PC602 SaveManager61 must not save without an active game")
        app.buttons["pc602-save61-back"].tap()
    }
    /// Real Apple iPad/iPhone simulator touch-to-drag regression.
    /// Exercises the same USTAWIENIA -> INTERFEJS path the user reported.
    /// Selecting by a touch MUST replace a previously different selection,
    /// so a default preselected heading cannot produce a false PASS.
    func testH290EditorDirectTouchSelectDragAndCancel() {
        let app=XCUIApplication()
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"]="1"
        app.launch()
        waitForActualW3Menu(app)
        app.buttons["w3-home-2"].tap()
        let enter=app.buttons["campaign-enter-original-orbit291"]
        require(enter,"Original H290 campaign is unavailable")
        enter.tap()
        let pause=app.buttons["pc602-orbit-pause"]
        require(pause,"H290 live HUD did not render",timeout:90)
        pause.tap()
        let settings=app.buttons["pc602-orbit-options-settings"]
        require(settings,"Unified source PAUZA lacks USTAWIENIA")
        settings.tap()
        let edit=app.buttons["w3-interface-edit-orbit-hud291"]
        require(edit,"HUD editor must be under USTAWIENIA / INTERFEJS")
        edit.tap()
        let save=app.buttons["pc602-orbit-hud-editor-save"]
        require(save,"Native H290 HUD editing screen did not open")
        let heading=byID(app,"pc602-h290-hud-atlas-title")
        require(heading,"Actual on-screen H290 atlas heading is not exposed")
        let next=app.buttons["pc602-orbit-hud-next"]
        require(next,"HUD element navigation missing")
        next.tap()
        let inspector=app.buttons["pc602-orbit-hud-inspector-toggle"]
        require(inspector,"HUD inspector missing")
        inspector.tap()
        require(app.staticTexts["HUD / NAZWA CELU"],
                "Next element should be the independent mission target label")
        let original=heading.frame
        XCTAssertGreaterThan(original.width,0,"Actual heading has zero width")
        let origin=app.coordinate(withNormalizedOffset:CGVector(dx:0,dy:0))
            .withOffset(CGVector(dx:original.midX,dy:original.midY))
        origin.tap()
        require(app.staticTexts["HUD / TYTUŁ ATLASU"],
                "Touch must SELECT the actual atlas heading, not keep menu selection")
        // Source HudEditorTouchCanvas drag: begin from actual displayed
        // text, then move 38 physical points; the rendered text must follow.
        origin.press(forDuration:0.2,
                     thenDragTo:origin.withOffset(CGVector(dx:38,dy:0)))
        let changed=heading.frame
        XCTAssertGreaterThan(changed.minX,original.minX+9,
            "Finger drag failed to move the real H290 HUD widget")
        let cancel=app.buttons["ANULUJ"]
        require(cancel,"HUD editor cannot return to USTAWIENIA")
        cancel.tap()
        require(byID(app,"pc602-orbit-settings-fullscreen"),
                "Cancel must restore the settings screen, not a second pause")
    }


    /// Checks ALL native H290 control buttons rather than only a text
    /// widget. The real H290 editor must intercept these physical touches
    /// before the paused/disabled game buttons receive them.
    func testH290AllFiveControlButtonsTouchDragSaveReopen() {
        let app=XCUIApplication()
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"]="1"
        app.launch()
        waitForActualW3Menu(app)
        app.buttons["w3-home-2"].tap()
        let enterOrbit=app.buttons["campaign-enter-original-orbit291"]
        require(enterOrbit,"Original PC602 world not available")
        enterOrbit.tap()
        let pause=app.buttons["pc602-orbit-pause"]
        require(pause,"Live H290 HUD missing",timeout:90)

        let controls:[(String,String)]=[
            ("pc602-orbit-open-options291","PRZYCISK / PAUZA (GÓRA)"),
            ("pc602-orbit-open-atlas330","PRZYCISK / ATLAS"),
            ("pc602-orbit-next-sector","PRZYCISK / CEL +"),
            ("pc602-orbit-pause","PRZYCISK / PAUZA"),
            ("pc602-orbit-enter-context","PRZYCISK / WEJDŹ")
        ]
        var positions:[String:CGRect]=[:]
        for (identifier,_) in controls {
            let button=byID(app,identifier)
            require(button,"Actual H290 control missing: "+identifier)
            XCTAssertGreaterThan(button.frame.width,0)
            positions[identifier]=button.frame
        }
        pause.tap()
        let settings=app.buttons["pc602-orbit-options-settings"]
        require(settings,"Original H290 settings not available")
        settings.tap()
        let edit=app.buttons["w3-interface-edit-orbit-hud291"]
        require(edit,"H290 HUD editor is not in USTAWIENIA / INTERFEJS")
        edit.tap()
        require(app.buttons["pc602-orbit-hud-editor-save"],
                "H290 editor did not open")
        let inspector=app.buttons["pc602-orbit-hud-inspector-toggle"]
        require(inspector,"H290 inspector missing")

        func physicalCenter(_ frame:CGRect)->XCUICoordinate {
            app.coordinate(withNormalizedOffset:CGVector(dx:0,dy:0))
               .withOffset(CGVector(dx:frame.midX,dy:frame.midY))
        }
        for (identifier,title) in controls {
            guard let rect=positions[identifier] else {
                XCTFail("Missing physical frame: "+identifier)
                return
            }
            physicalCenter(rect).tap()
            inspector.tap()
            require(app.staticTexts[title],
                    "Touch must select the actual rendered control: "+identifier)
            inspector.tap()
        }

        let enterButton=byID(app,"pc602-orbit-enter-context")
        let old=enterButton.frame
        let touch=physicalCenter(old)
        touch.press(forDuration:0.20,
                    thenDragTo:touch.withOffset(CGVector(dx:-42,dy:-27)))
        let moved=enterButton.frame
        XCTAssertLessThan(moved.midX,old.midX-8,
            "WEJDŹ must move directly under touch, clear of the editor toolbar")
        let save=app.buttons["pc602-orbit-hud-editor-save"]
        save.tap()
        require(byID(app,"pc602-orbit-settings-fullscreen"),
                "Save should return to settings only after persisting the layout")
        let saved=enterButton.frame
        edit.tap()
        require(app.buttons["pc602-orbit-hud-editor-save"],
                "Reopened editor missing after save")
        let reopened=byID(app,"pc602-orbit-enter-context").frame
        XCTAssertEqual(reopened.midX,saved.midX,accuracy:3,
            "WEJDŹ position must survive closing and reopening the editor")
        XCTAssertEqual(reopened.midY,saved.midY,accuracy:3,
            "Saved WEJDŹ Y offset must not snap back")
        app.buttons["ANULUJ"].tap()
    }

}
