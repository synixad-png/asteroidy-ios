import XCTest

/// Live iPhone/iPad XCTest: production app must demand START after audio.
/// No verification bypass flag is set in this class.
final class W3StartupSplashUITests: XCTestCase {
    func testStartupPressEnterRequiredAfterMusic() {
        let app=XCUIApplication()
        XCUIDevice.shared.orientation = .landscapeRight
        app.launch()
        let splash=app.buttons["w3-startup-enter"]
        XCTAssertTrue(splash.waitForExistence(timeout:180),
             "Source audio must finish before the original startup gate appears")
        XCTAssertFalse(app.buttons["w3-home-0"].exists,
             "W3 HOME must not accept input before Enter/touch")
        splash.tap()
        XCTAssertTrue(app.buttons["w3-home-0"].waitForExistence(timeout:20),
             "Touching source startup gate must uncover W3 HOME")
        XCTAssertFalse(app.buttons["w3-startup-enter"].exists,
             "Startup splash cannot remain above the live menu after transition")
    }
}
