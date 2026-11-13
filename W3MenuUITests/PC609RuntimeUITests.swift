import XCTest

/// Device-simulator verification of exact embedded PC609 ship selection
/// and the two routes reported black on the user's iPad. Real app + Metal;
/// no mocked 3D frames and no change to production gameplay.
final class PC609RuntimeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure=false
        XCUIDevice.shared.orientation = .landscapeRight
    }

    private func byID(_ app:XCUIApplication,_ id:String)->XCUIElement {
        app.descendants(matching:.any).matching(identifier:id).firstMatch
    }

    private func startApp()->XCUIApplication {
        let app=XCUIApplication()
        app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"]="1"
        app.launchEnvironment["ASTEROIDY_H290_SIMULATOR_UI_VERIFY"]="1"
        app.launch()
        let home=app.buttons["w3-home-0"]
        for _ in 0..<6 {
            if home.waitForExistence(timeout:60) {return app}
        }
        XCTFail("Oryginalne W3 nie wstało po przygotowaniu muzyki")
        return app
    }

    func testThreeVerifiedShipsAreSelectibleWithoutFilesImport() {
        let app=startApp()
        let new=app.buttons["w3-home-0"]
        XCTAssertTrue(new.exists)
        new.tap()
        let start=app.buttons["w3-new-start-source"]
        XCTAssertTrue(start.waitForExistence(timeout:30))
        for ship in 0..<3 {
            let choice=app.buttons["w3-new-ship-\(ship)"]
            XCTAssertTrue(choice.waitForExistence(timeout:20),
                          "Brak oryginalnego wyboru statku PC609 numer \(ship)")
            XCTAssertTrue(choice.isEnabled,
                          "Oryginalny PC609 statek \(ship) nie ładuje się z IPA")
            choice.tap()
            XCTAssertTrue(start.isEnabled,
                          "Nie można rozpocząć kampanii statkiem \(ship)")
        }
        let screenshot=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        screenshot.name="REAL-SIM-PC609-three-ship-new-game"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["w3-panel-back"].tap()
        let hangar=app.buttons["w3-home-3"]
        XCTAssertTrue(hangar.waitForExistence(timeout:20))
        // H55 scene itself needs the separately user-imported hangar_h55.glb.
        // Never pretend the original hangar can run on this fresh simulator
        // without that asset; the three ship imports are gone from the source.
    }

    func testFreshCampaignOrbitThenCarbonisMission01WithoutBlackError() {
        let app=startApp()
        app.buttons["w3-home-0"].tap()
        XCTAssertTrue(app.buttons["w3-new-start-source"]
            .waitForExistence(timeout:30))
        let vanguard=app.buttons["w3-new-ship-1"]
        XCTAssertTrue(vanguard.waitForExistence(timeout:20))
        vanguard.tap()
        app.buttons["w3-new-start-source"].tap()
        let accept=app.buttons["w3-new-accept-confirmation"]
        if accept.waitForExistence(timeout:3) {accept.tap()}

        let orbit=byID(app,"pc602-orbit-live-metal")
        if !orbit.waitForExistence(timeout:50) {
            // Record exact visible application error in a REAL simulator
            // without inventing an alternative scene or claiming success.
            let texts=app.staticTexts.allElementsBoundByIndex.prefix(90)
                .map { $0.label }.filter { !$0.isEmpty }
            let buttons=app.buttons.allElementsBoundByIndex.prefix(60)
                .map { "\($0.identifier):\($0.label)" }
            print("PC609_NEW_GAME_FAILURE_VISIBLE_TEXTS: \(texts)")
            print("PC609_NEW_GAME_FAILURE_VISIBLE_BUTTONS: \(buttons)")
            let failureShot=XCTAttachment(
                screenshot:XCUIScreen.main.screenshot())
            failureShot.name="REAL-SIM-PC609-newgame-orbit-failure"
            failureShot.lifetime = .keepAlways
            add(failureShot)
            XCTFail("Nowa kampania nie otworzyła H290 Metal. " +
                    "Widoczne komunikaty: \(texts)")
            return
        }
        XCTAssertTrue(app.buttons["pc602-orbit-pause"].waitForExistence(timeout:20))
        XCTAssertFalse(byID(app,"pc602-orbit-renderer-recovery").exists,
                       "H290 uruchomił błąd renderer missing/metal")
        let orbitImage=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        orbitImage.name="REAL-SIM-PC609-fresh-home-orbit"
        orbitImage.lifetime = .keepAlways
        add(orbitImage)

        app.buttons["pc602-orbit-open-options291"].tap()
        let exit=app.buttons["pc602-orbit-return-w3"]
        XCTAssertTrue(exit.waitForExistence(timeout:30))
        exit.tap()
        let campaign=app.buttons["w3-home-2"]
        XCTAssertTrue(campaign.waitForExistence(timeout:40))
        campaign.tap()
        let mission=app.buttons["campaign-enter-source-sector01"]
        XCTAssertTrue(mission.waitForExistence(timeout:30))
        mission.tap()

        let intro=byID(app,"mission-intro41-cinematic-568")
        XCTAssertTrue(intro.waitForExistence(timeout:120),
                      "Misja 01 nie otworzyła prawdziwej animacji Intro41")
        let skip=app.buttons["intro41-skip-to-real-mission"]
        XCTAssertTrue(skip.waitForExistence(timeout:30))
        let introImage=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        introImage.name="REAL-SIM-PC609-Carbonis01-Intro41"
        introImage.lifetime = .keepAlways
        add(introImage)
        XCTAssertTrue(skip.isEnabled,
                      "Animacja Intro41 nie rusza, możliwy czarny ekran")
        skip.tap()
        XCTAssertTrue(byID(app,"sector01-real-source-scene")
             .waitForExistence(timeout:90),
             "Misja 01 nie przechodzi do rzeczywistej walki 3D")
        let combatImage=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        combatImage.name="REAL-SIM-PC609-Carbonis01-combat"
        combatImage.lifetime = .keepAlways
        add(combatImage)
    }
}
