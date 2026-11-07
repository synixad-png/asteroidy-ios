import Foundation

/// Real Windows v568 startup contract: Program.cs:94,91,120-123,227;
/// ProgramW3Native315.cs:26-30; UiW3NativeLayout315.cs:455-470.
/// Source W3 startup does NOT time out after legacy v281's 4.4 seconds.
/// The original soundtrack begins after MusicBank.Prepare; menu navigation
/// remains locked until the player explicitly confirms START.
enum W3StartupPolicy568 {
    enum Phase: Equatable {
        case preparingMusic
        case awaitingEnter
        case mainMenu
    }
    static let sourceCoverSeconds:Double=0.45
    static let sourceUncoverSeconds:Double=0.80
    static let originalWidth:Double=1280
    static let originalHeight:Double=720

    static func phase(musicReady:Bool,confirmed:Bool)->Phase {
        if !musicReady {return .preparingMusic}
        return confirmed ? .mainMenu : .awaitingEnter
    }
    /// Explicit source/UI verification is separate from ordinary startup.
    /// Unmodified public app launches always display the splash once.
    static func skipForDiagnostic(_ env:[String:String])->Bool {
        ["ASTEROIDY_W3_MENU_VERIFY","ASTEROIDY_RENDER_VERIFY",
         "ASTEROIDY_SHIP367_VERIFY"].contains {env[$0]=="1"}
    }
    static func isSourceActivation(_ key:String)->Bool {
        key=="enter" || key=="space" || key=="touch" ||
        key=="gamepadA" || key=="gamepadStart"
    }
    static func referencePromptAlpha(_ seconds:Double)->Double {
        let pulse=0.65+0.35*sin(seconds*2.73)
        let opacity=max(140.0,min(255.0,Double(Int(240*pulse))))
        return opacity/255
    }
}
