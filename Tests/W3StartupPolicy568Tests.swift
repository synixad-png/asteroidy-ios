import Foundation

@main struct W3StartupPolicy568Tests {
    static func main() {
        var n=0
        func check(_ yes:Bool,_ title:String) {
            precondition(yes,title);n+=1
        }
        check(W3StartupPolicy568.originalWidth==1280 &&
              W3StartupPolicy568.originalHeight==720,
              "W3 source canvas exactly 1280x720")
        check(W3StartupPolicy568.phase(musicReady:false,confirmed:false)
              == .preparingMusic, "no splash before source audio is ready")
        check(W3StartupPolicy568.phase(musicReady:true,confirmed:false)
              == .awaitingEnter, "music ready must NOT automatically open menu")
        check(W3StartupPolicy568.phase(musicReady:true,confirmed:true)
              == .mainMenu, "confirmed startup enters W3 home")
        check(W3StartupPolicy568.phase(musicReady:false,confirmed:true)
              == .preparingMusic, "confirmation cannot bypass audio loading")
        for key in ["enter","space","touch","gamepadA","gamepadStart"] {
            check(W3StartupPolicy568.isSourceActivation(key),
                  "original W3 supports \(key)")
        }
        for key in ["escape","up","left","auto","timeout"] {
            check(!W3StartupPolicy568.isSourceActivation(key),
                  "source W3 forbids startup input \(key)")
        }
        check(abs(W3StartupPolicy568.sourceCoverSeconds-0.45)<1e-9 &&
              abs(W3StartupPolicy568.sourceUncoverSeconds-0.8)<1e-9,
              "exact 36% cover and 64% uncover of 1.25 second shutter")
        check(!W3StartupPolicy568.skipForDiagnostic([:]),
              "production always presents W3 splash")
        check(W3StartupPolicy568.skipForDiagnostic(
              ["ASTEROIDY_W3_MENU_VERIFY":"1"]),
              "existing UI nav diagnostics may bypass splash")
        check(W3StartupPolicy568.skipForDiagnostic(
              ["ASTEROIDY_RENDER_VERIFY":"1"]),
              "existing GPU verification remains intact")
        check(W3StartupPolicy568.skipForDiagnostic(
              ["ASTEROIDY_SHIP367_VERIFY":"1"]),
              "original ship367 visual verification remains intact")
        check(!W3StartupPolicy568.skipForDiagnostic(
              ["ASTEROIDY_W3_MENU_VERIFY":"0"]),
              "normal app with unset verification never bypasses")
        let first=W3StartupPolicy568.referencePromptAlpha(0)
        let second=W3StartupPolicy568.referencePromptAlpha(1.0)
        check(first>=140.0/255 && first<=240.0/255 &&
              abs(first-second)>0.03,
              "prompt alpha pulses with source 2.73-rad/sec motion")
        print("PASS \(n) source W3 splash gate and original input contracts")
    }
}
