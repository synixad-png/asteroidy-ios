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

    /// An authentic on-screen capture from the installed simulator build.
    /// Sampling the center excludes most HUD labels; a flat/black GPU
    /// viewport cannot pass just because the SwiftUI overlay is visible.
    private func captureNonFlatFrame(_ tag:String) {
        let screenshot=XCUIScreen.main.screenshot()
        let attachment=XCTAttachment(screenshot:screenshot)
        attachment.name="REAL-SIM-PC609-" + tag
        attachment.lifetime = .keepAlways
        add(attachment)

        guard let source=screenshot.image.cgImage else {
            XCTFail("Real simulator screenshot has no CGImage: " + tag)
            return
        }
        let w=96,h=54
        var pixels=[UInt8](repeating:0,count:w*h*4)
        pixels.withUnsafeMutableBytes { memory in
            guard let context=CGContext(
                data:memory.baseAddress,width:w,height:h,
                bitsPerComponent:8,bytesPerRow:4*w,
                space:CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)
            else {return}
            context.interpolationQuality = .high
            context.draw(source,in:CGRect(x:0,y:0,width:w,height:h))
        }
        var distinct=Set<Int>()
        var nonDark=0,maxChannel=0
        let xRange=(w/4)..<(w*3/4)
        let yRange=(h/4)..<(h*3/4)
        for y in yRange {
            for x in xRange {
                let i=4*(y*w+x)
                let r=Int(pixels[i]),g=Int(pixels[i+1]),b=Int(pixels[i+2])
                let bright=max(r,max(g,b))
                maxChannel=max(maxChannel,bright)
                if bright>35 {nonDark+=1}
                distinct.insert((r/16)<<8 | (g/16)<<4 | (b/16))
            }
        }
        print("PC609_REAL_FRAME_ANALYSIS_\\(tag): nonDark=\\(nonDark), distinct16=\\(distinct.count), max=\\(maxChannel)")
        XCTAssertGreaterThan(distinct.count,10,
            "Flat/black central GPU screen in real Apple simulator: " + tag)
        XCTAssertGreaterThan(nonDark,0,
            "No illuminated original 3D scene pixels: " + tag)
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

        // PC602HomeScene291 is MTKView, NOT an exposed accessibility
        // element. Earlier tests incorrectly interpreted a missing MTKView
        // identifier as missing gameplay, although the real HUD was visible.
        let realHud=app.staticTexts.matching(NSPredicate(
            format:"label CONTAINS[c] %@", "ATLAS 01")).firstMatch
        let realPause=app.buttons["pc602-orbit-pause"]
        XCTAssertTrue(realHud.waitForExistence(timeout:50),
                      "Nowa kampania nie wyświetla HUD oryginalnego H290")
        XCTAssertTrue(realPause.waitForExistence(timeout:25),
                      "Zasłonięte oryginalne przyciski H290 / dostępność")
        XCTAssertFalse(byID(app,"pc602-orbit-renderer-recovery").exists,
                       "Renderer H290 reported a real Metal/GLB error")
        captureNonFlatFrame("H290-HomeOrbit-Vanguard")
        // Exercise the genuine original pause/exit controls rather than
        // a nonexistent accessibility node inside the raw MTKView.
        realPause.tap()
        let exit=app.buttons["pc602-orbit-return-w3"]
        XCTAssertTrue(exit.waitForExistence(timeout:30))
        exit.tap()
        let campaign=app.buttons["w3-home-2"]
        XCTAssertTrue(campaign.waitForExistence(timeout:40))
        campaign.tap()
        let mission=app.buttons["campaign-enter-source-sector01"]
        XCTAssertTrue(mission.waitForExistence(timeout:30))
        mission.tap()

        // A SwiftUI page identifier is not a GPU frame and can be inherited
        // by all children. Verify the ACTUAL intro HUD and a real screenshot,
        // then transition to Carbonis combat.
        let heading=app.staticTexts["SYNIXAD / ROZPOCZĘCIE MISJI"]
        let combatPause=app.buttons["sector01-pause-button"]
        let introAppeared=heading.waitForExistence(timeout:35)
        XCTAssertTrue(introAppeared || combatPause.waitForExistence(timeout:10),
                      "CARBONIS 01 did not open original Intro41 or real combat")
        if introAppeared {
            let error=app.staticTexts.matching(NSPredicate(
                format:"label CONTAINS %@", "METAL")).firstMatch
            if error.exists {
                print("PC609_INTRO41_VISIBLE_METAL_DIAGNOSTIC=\\(error.label)")
            }
            captureNonFlatFrame("CARBONIS01-Intro41")
            let skip=app.buttons["intro41-skip-to-real-mission"]
            if skip.waitForExistence(timeout:12) {
                let enabled=NSPredicate(format:"isEnabled == true")
                let ready=expectation(for:enabled,evaluatedWith:skip)
                wait(for:[ready],timeout:20)
                if skip.exists && skip.isEnabled {skip.tap()}
            }
        }
        XCTAssertTrue(combatPause.waitForExistence(timeout:75),
                      "CARBONIS 01 failed to enter actual combat scene after Intro41")
        captureNonFlatFrame("CARBONIS01-Combat")
    }
}
