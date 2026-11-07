import Foundation
import SwiftUI
import UIKit
import GameController

/// Exact W3 "splash" phase after OriginalAudioAV568 has completed
/// the sound effects + two menu tracks. Reuses *the same* SHA-verified
/// W3 background and logo objects already cached by W3MainMenu568.
/// References: UiW3NativeLayout315.DrawW3Splash323 / W3Header / W3Footer;
/// ProgramW3Native315.SkipW3Startup327, source 0.45s + 0.80s shutter.
/// No static 4.4s auto skip (that belongs only to the legacy title143).
struct W3StartupSplash568: View {
    var onContinue:()->Void
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var keyboardFocused:Bool
    @State private var stage=Stage.waiting
    @State private var wipe:CGFloat=0
    @StateObject private var pad=W3StartupGamepad568()

    private enum Stage {case waiting,cover,uncover}
    private let gold=Color(red:225/255,green:167/255,blue:77/255)
    private let cyan=Color(red:99/255,green:191/255,blue:202/255)
    private let paper=Color(red:225/255,green:232/255,blue:235/255)
    private let muted=Color(red:164/255,green:188/255,blue:199/255)

    private func proceed() {
        guard stage == .waiting else {return}
        // Source input immediately starts the approved W3 wipe.
        stage = .cover
        withAnimation(.timingCurve(0.58,0.05,0.28,1,duration:
                      W3StartupPolicy568.sourceCoverSeconds)) {
            wipe = 1
        }
        DispatchQueue.main.asyncAfter(deadline:.now()+
                    W3StartupPolicy568.sourceCoverSeconds) {
            guard stage == .cover else{return}
            // At full cover, the already-mounted authentic W3 HOME replaces
            // the outgoing splash beneath the native left-to-right veil.
            var immediate=Transaction()
            immediate.disablesAnimations=true
            withTransaction(immediate) {
                stage = .uncover
                wipe = 0
            }
            withAnimation(.timingCurve(0.22,0.7,0.15,1,duration:
                          W3StartupPolicy568.sourceUncoverSeconds)) {
                wipe = 1
            }
            DispatchQueue.main.asyncAfter(deadline:.now()+
                        W3StartupPolicy568.sourceUncoverSeconds) {
                guard stage == .uncover else {return}
                onContinue()
            }
        }
    }

    private var sourcePage:some View {
        ZStack(alignment:.topLeading) {
            // Source header 0..74; footer 652..720.
            Rectangle()
                .fill(Color(red:1/255,green:8/255,blue:14/255).opacity(0.969))
                .frame(width:1280,height:74)
                .position(x:640,y:37)
            Rectangle().fill(muted.opacity(0.40))
                .frame(width:1280,height:1).position(x:640,y:74)
            if let logo=SourceW3Images568.pair?.logo {
                Image(uiImage:logo).resizable().aspectRatio(contentMode:.fit)
                    .frame(width:186,height:54)
                    .position(x:131,y:44)
            }
            Rectangle().fill(cyan.opacity(0.3))
                .frame(width:1,height:38).position(x:246,y:37)
            Text("S Y N I X A D   S Y S T E M S")
                .font(.system(size:15,weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
                .frame(width:440,alignment:.leading).position(x:484,y:29)
            Text("ORBITAL NAVIGATION SYSTEM")
                .font(.system(size:13,design:.monospaced))
                .foregroundStyle(paper)
                .frame(width:440,alignment:.leading).position(x:484,y:51)
            Text("TRYB START").font(.system(size:14,design:.monospaced))
                .foregroundStyle(paper)
                .frame(width:320,alignment:.trailing).position(x:1080,y:38)

            Text("NOWY SYSTEM NAWIGACJI")
                .font(.system(size:17,weight:.medium,design:.monospaced))
                .foregroundStyle(gold)
                .frame(width:440).position(x:640,y:213)
            if let logo=SourceW3Images568.pair?.logo {
                let height=350*logo.size.height/max(1,logo.size.width)
                Image(uiImage:logo).resizable().aspectRatio(contentMode:.fit)
                    .frame(width:350,height:height)
                    .position(x:640,y:234+height/2)
                    .accessibilityHidden(true)
            }
            Text("ORBITAL NAVIGATION SYSTEM")
                .font(.system(size:18,weight:.medium,design:.monospaced))
                .foregroundStyle(cyan)
                .frame(width:460).position(x:640,y:367)
            TimelineView(.animation(minimumInterval:1.0/30.0,
                                    paused:stage != .waiting)) { timeline in
                Button(action:proceed) {
                    Text("NACIŚNIJ ENTER / START")
                        .font(.system(size:21,weight:.semibold,design:.monospaced))
                        .foregroundStyle(Color(red:202/255,green:219/255,
                                               blue:224/255).opacity(
                            W3StartupPolicy568.referencePromptAlpha(
                                timeline.date.timeIntervalSinceReferenceDate)))
                        .frame(width:382,height:48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x:640,y:416)
                .accessibilityIdentifier("w3-startup-enter")
                .accessibilityLabel("Naciśnij Enter albo dotknij, aby wejść do menu")
            }
            Rectangle().fill(muted.opacity(0.7))
                .frame(width:326,height:1).position(x:640,y:442)
            Text("TERMINAL // SYNIXAD COMMAND")
                .font(.system(size:14,design:.monospaced))
                .foregroundStyle(muted)
                .frame(width:480,alignment:.leading).position(x:300,y:634)
            Text("STATUS POŁĄCZENIA: AKTYWNY")
                .font(.system(size:14,design:.monospaced))
                .foregroundStyle(muted)
                .frame(width:430,alignment:.trailing).position(x:1003,y:634)
            Rectangle()
                .fill(Color(red:1/255,green:8/255,blue:14/255).opacity(0.969))
                .frame(width:1280,height:68)
                .position(x:640,y:686)
            Rectangle().fill(muted.opacity(0.42))
                .frame(width:1280,height:1).position(x:640,y:652)
            Text("STRZAŁKI / DPAD WYBÓR     ·     ENTER / A ZATWIERDŹ")
                .font(.system(size:14,design:.monospaced))
                .foregroundStyle(paper)
                .frame(width:950,alignment:.leading)
                .position(x:514,y:680)
            Text("UI W3 / OPENGL")
                .font(.system(size:13,design:.monospaced))
                .foregroundStyle(gold)
                .frame(width:165,alignment:.trailing).position(x:1170,y:680)
        }
        .frame(width:1280,height:720)
    }

    var body:some View {
        GeometryReader { geo in
            let fit=min(geo.size.width/1280,geo.size.height/720)
            ZStack {
                if stage != .uncover {
                    if let images=SourceW3Images568.pair {
                        Image(uiImage:images.background).resizable()
                            .scaledToFill()
                            .frame(width:geo.size.width,height:geo.size.height)
                            .clipped()
                            .overlay(Color(red:0.004,green:0.035,
                                           blue:0.067).opacity(0.65))
                    } else {
                        Color(red:0.006,green:0.02,blue:0.035)
                    }
                    sourcePage
                        .scaleEffect(fit)
                        .frame(width:geo.size.width,height:geo.size.height)
                }
                if stage != .waiting {
                    // Reference wipe covers/unveils only y=66..666.
                    // One solid native curtain, no second menu image.
                    Rectangle().fill(Color(red:4/255,green:16/255,
                                            blue:27/255).opacity(0.988))
                        .frame(width:geo.size.width * (stage == .cover
                            ? wipe : 1-wipe),
                               height:geo.size.height*600/720)
                        .position(
                            x:stage == .cover
                              ? geo.size.width*wipe/2
                              : geo.size.width*(wipe+(1-wipe)/2),
                            y:geo.size.height*366/720)
                        .accessibilityHidden(true)
                }
                // Shield underlying menu input even while the curtain unveils.
                Color.clear.contentShape(Rectangle())
                    .allowsHitTesting(stage != .waiting)
            }
            .frame(width:geo.size.width,height:geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture {proceed()}
        }
        .ignoresSafeArea()
        .focusable(true)
        .focused($keyboardFocused)
        .onKeyPress(.return) { _ in proceed();return .handled }
        .onKeyPress(.space) { _ in proceed();return .handled }
        .onAppear {
            keyboardFocused=true
            pad.start(onConfirm:proceed)
        }
        .onDisappear {pad.stop()}
        .onChange(of:scenePhase) { phase in
            if phase == .active {keyboardFocused=true}
        }
        .accessibilityIdentifier("w3-original-startup-splash")
    }
}

/// Source Program.cs:263 gamepad A / Start skips W3 splash.
/// Attach only for the title; releasing the handlers at dismissal avoids
/// replacing normal mission/controller behavior after the start gate.
final class W3StartupGamepad568:ObservableObject {
    private var subscriptions:[NSObjectProtocol]=[]
    private var configured:[GCController]=[]
    private var action:(()->Void)?
    func start(onConfirm:@escaping ()->Void) {
        guard subscriptions.isEmpty else{return}
        action=onConfirm
        let center=NotificationCenter.default
        subscriptions.append(center.addObserver(
            forName:.GCControllerDidConnect,object:nil,queue:.main) {
            [weak self] event in
            if let controller=event.object as? GCController {
                self?.configure(controller)
            }
        })
        subscriptions.append(center.addObserver(
            forName:.GCControllerDidDisconnect,object:nil,queue:.main) {
            [weak self] event in
            if let controller=event.object as? GCController {
                self?.configured.removeAll {$0 === controller}
            }
        })
        for controller in GCController.controllers() {configure(controller)}
    }
    private func configure(_ controller:GCController) {
        guard !configured.contains(where:{$0===controller}),
              let pad=controller.extendedGamepad else{return}
        configured.append(controller)
        pad.buttonA.pressedChangedHandler = {[weak self] _,_,pressed in
            if pressed {DispatchQueue.main.async {self?.action?()}}
        }
        pad.buttonMenu?.pressedChangedHandler = {[weak self] _,_,pressed in
            if pressed {DispatchQueue.main.async {self?.action?()}}
        }
    }
    func stop() {
        for controller in configured {
            controller.extendedGamepad?.buttonA.pressedChangedHandler=nil
            controller.extendedGamepad?.buttonMenu?.pressedChangedHandler=nil
        }
        configured.removeAll()
        subscriptions.forEach {NotificationCenter.default.removeObserver($0)}
        subscriptions.removeAll()
        action=nil
    }
    deinit {stop()}
}
