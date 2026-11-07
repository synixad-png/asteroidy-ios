import SwiftUI
import UIKit

/// UIWindow-level safe-area reporter for immersive landscape W3 screens.
/// SwiftUI's GeometryProxy.safeAreaInsets can be zero when a parent uses
/// .ignoresSafeArea(), so query the actual window instead. The original
/// W3 background remains edge-to-edge; only controls and captions use
/// these insets. No screen-model names, pixel offsets or polling timers.
struct W3SafeAreaReader568:UIViewRepresentable {
    @Binding var insets:W3ScreenInsets568

    final class ProbeView:UIView {
        var onInsetsChanged:((W3ScreenInsets568)->Void)?
        private var previous:W3ScreenInsets568?

        func publishInsets() {
            guard let window=window else{return}
            let safe=window.safeAreaInsets
            let value=W3ScreenInsets568(
                top:Double(safe.top),left:Double(safe.left),
                bottom:Double(safe.bottom),right:Double(safe.right))
            guard value != previous else{return}
            previous=value
            onInsetsChanged?(value)
        }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            publishInsets()
        }
        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            publishInsets()
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            publishInsets()
        }
    }

    func makeUIView(context:Context)->ProbeView {
        let view=ProbeView(frame:.zero)
        view.isUserInteractionEnabled=false
        view.isOpaque=false
        view.backgroundColor = .clear
        return view
    }
    func updateUIView(_ view:ProbeView,context:Context) {
        let binding=_insets
        view.onInsetsChanged={ value in
            // UIKit may call layoutSubviews while SwiftUI is reconciling.
            // Send back only actual device/rotation changes, asynchronously.
            DispatchQueue.main.async {
                if binding.wrappedValue != value {
                    binding.wrappedValue=value
                }
            }
        }
        view.publishInsets()
    }
}
