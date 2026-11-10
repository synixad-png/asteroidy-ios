import Foundation
import UIKit
import SwiftUI
import GameController

/// One physical keyboard/gamepad adaptor. All PC IDs/combos/deadzones
/// live in SourceControls586, not duplicated in native UIKit handlers.
/// No own render loop, repeating timer, polling service or global hooks.
final class SourceHardwareInput586 {
    static let shared=SourceHardwareInput586()
    private(set) var pressed:Set<Int>=[]
    private init() {}

    func changeKey(_ code:Int,pressed down:Bool) {
        guard code>0 else{return}
        if down {pressed.insert(code)}
        else {pressed.remove(code)}
    }
    func clearKeyboard() {pressed.removeAll()}

    func snapshot()->SourceControls586.Snapshot {
        var buttons:Set<Int>=[]
        var axes:[Float]=Array(repeating:0,count:6)
        if let gamepad=GCController.controllers().first(where:{
            $0.extendedGamepad != nil
        })?.extendedGamepad {
            if gamepad.buttonA.isPressed {buttons.insert(0)}
            if gamepad.buttonB.isPressed {buttons.insert(1)}
            if gamepad.buttonX.isPressed {buttons.insert(2)}
            if gamepad.buttonY.isPressed {buttons.insert(3)}
            if gamepad.buttonOptions?.isPressed == true {buttons.insert(4)}
            if gamepad.buttonHome?.isPressed == true {buttons.insert(5)}
            if gamepad.buttonMenu.isPressed {buttons.insert(6)}
            if gamepad.leftThumbstickButton?.isPressed == true {
                buttons.insert(7)
            }
            if gamepad.rightThumbstickButton?.isPressed == true {
                buttons.insert(8)
            }
            if gamepad.leftShoulder.isPressed {buttons.insert(9)}
            if gamepad.rightShoulder.isPressed {buttons.insert(10)}
            if gamepad.dpad.up.isPressed {buttons.insert(11)}
            if gamepad.dpad.down.isPressed {buttons.insert(12)}
            if gamepad.dpad.left.isPressed {buttons.insert(13)}
            if gamepad.dpad.right.isPressed {buttons.insert(14)}
            axes[0]=gamepad.leftThumbstick.xAxis.value
            // SDL axes A1-/A3- mean up. Apple joystick Y positive=up.
            axes[1] = -gamepad.leftThumbstick.yAxis.value
            axes[2]=gamepad.rightThumbstick.xAxis.value
            axes[3] = -gamepad.rightThumbstick.yAxis.value
            axes[4]=gamepad.leftTrigger.value
            axes[5]=gamepad.rightTrigger.value
        }
        return SourceControls586.Snapshot(
            keys:pressed,buttons:buttons,axes:axes)
    }

    /// UIKit HID usage numbers, converted to PC v586 virtual-key IDs.
    /// This mapping is solely hardware translation; the configurable
    /// action routing stays in the ONE canonical source profile.
    static func windowsKey(fromHID hid:Int)->Int? {
        switch hid {
        case 4...29:return 65+hid-4 // A..Z
        case 30...38:return 49+hid-30 // 1..9
        case 39:return 48 // 0
        case 40,88:return 13 // Return / numpad Enter
        case 41:return 27 // Escape
        case 42:return 8 // Delete/backspace
        case 43:return 9 // Tab
        case 44:return 32 // Space
        case 45,86:return 189 // - / numpad -
        case 46,87:return 187 // = / numpad +
        case 54:return 188 // ,
        case 55:return 190 // .
        case 79:return 39 // right
        case 80:return 37 // left
        case 81:return 40 // down
        case 82:return 38 // up
        case 75:return 33 // Page Up
        case 78:return 34 // Page Down
        case 58...69:return 112+hid-58 // F1..F12
        case 84...85:return 111+hid-84 // Num / *, unavailable VK override
        case 89...97:return 97+hid-89 // Numpad 1..9
        case 98:return 96 // Numpad 0
        case 224:return 162 // left CTRL
        case 225:return 160 // left SHIFT
        case 226:return 164 // left ALT
        case 228:return 163 // right CTRL
        case 229:return 161 // right SHIFT
        case 230:return 165 // right ALT
        default:return nil
        }
    }
}

/// An invisible, *actual first-responder* UIView receives physical keyboard
/// presses in the playing mission. Touch halves remain untouched.
/// No UIKeyCommand global interception in the game's menus.
struct SourceKeyboardCapture586:UIViewRepresentable {
    var onKey:(Int,Bool)->Void

    final class Capture:UIView {
        var onKey:(Int,Bool)->Void = {_,_ in}
        override var canBecomeFirstResponder:Bool {true}

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                DispatchQueue.main.async { [weak self] in
                    _=self?.becomeFirstResponder()
                }
            }
        }
        private func deliver(_ presses:Set<UIPress>,down:Bool) {
            for press in presses {
                guard let key=press.key else{continue}
                let hid=Int(key.keyCode.rawValue)
                guard let pc=SourceHardwareInput586.windowsKey(fromHID:hid)
                else{continue}
                onKey(pc,down)
            }
        }
        override func pressesBegan(_ presses:Set<UIPress>,
                                  with event:UIPressesEvent?) {
            deliver(presses,down:true)
            // Recognized game controls are handled here, not forwarded into
            // UIKit navigation while gameplay owns keyboard focus.
        }
        override func pressesEnded(_ presses:Set<UIPress>,
                                  with event:UIPressesEvent?) {
            deliver(presses,down:false)
        }
        override func pressesCancelled(_ presses:Set<UIPress>,
                                      with event:UIPressesEvent?) {
            deliver(presses,down:false)
        }
    }

    func makeUIView(context:Context)->Capture {
        let view=Capture(frame:.zero)
        view.backgroundColor = .clear
        view.onKey=onKey
        return view
    }
    func updateUIView(_ view:Capture,context:Context) {
        view.onKey=onKey
    }
    static func dismantleUIView(_ view:Capture,coordinator:()) {
        view.resignFirstResponder()
        SourceHardwareInput586.shared.clearKeyboard()
    }
}
