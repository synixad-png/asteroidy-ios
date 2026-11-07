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
    @State private var safeInsets=W3ScreenInsets568()

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
        DispatchQueue.main.asyncAfter(
            deadline:.now() + W3StartupPolicy568.sourceCoverSeconds) {
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
            DispatchQueue.main.asyncAfter(
                deadline:.now() + W3StartupPolicy568.sourceUncoverSeconds) {
                guard stage == .uncover else {return}
                onContinue()
            }
        }
    }

    // Source W3Header/W3Footer chrome fills the *actual* screen.
    // Unlike the former scaled 1280x720 sheet, no 4:3 letterboxing:
    // the header starts at physical y=0 and footer ends at y=height.
    private func sourceHeader(_ layout:W3AdaptiveViewport568)->some View {
        let scale=layout.sourceScale
        return HStack(spacing:layout.compact ? 7 : 18) {
            if let logo=SourceW3Images568.pair?.logo {
                Image(uiImage:logo).resizable().scaledToFit()
                    .frame(width:layout.headerLogoWidth,
                           height:(layout.headerHeight-layout.safeTop)*0.73)
            }
            Rectangle().fill(cyan.opacity(0.3))
                .frame(width:1,height:layout.headerHeight*0.51)
            VStack(alignment:.leading,spacing:3) {
                Text("S Y N I X A D   S Y S T E M S")
                    .font(.system(size:15*scale,weight:.bold,design:.monospaced))
                    .foregroundStyle(gold)
                Text("ORBITAL NAVIGATION SYSTEM")
                    .font(.system(size:13*scale,design:.monospaced))
                    .foregroundStyle(paper)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            Spacer(minLength:5)
            Text("TRYB START")
                .font(.system(size:14*scale,design:.monospaced))
                .foregroundStyle(paper)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .padding(.leading,layout.leadingPadding)
        .padding(.trailing,layout.trailingPadding)
        .padding(.top,layout.safeTop)
        .frame(width:layout.width,height:layout.headerHeight)
        .background(Color(red:1/255,green:8/255,blue:14/255).opacity(0.969))
        .overlay(alignment:.bottom) {
            Rectangle().fill(muted.opacity(0.40)).frame(height:1)
        }
        .accessibilityIdentifier("w3-startup-header-top")
    }

    private func sourceFooter(_ layout:W3AdaptiveViewport568)->some View {
        HStack(spacing:8) {
            Text("STRZAŁKI / DPAD WYBÓR     ·     ENTER / A ZATWIERDŹ")
                .font(.system(size:14*layout.sourceScale,design:.monospaced))
                .foregroundStyle(paper)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Spacer(minLength:4)
            Text("UI W3 / OPENGL")
                .font(.system(size:13*layout.sourceScale,design:.monospaced))
                .foregroundStyle(gold)
                .lineLimit(1)
        }
        .padding(.leading,layout.leadingPadding)
        .padding(.trailing,layout.trailingPadding)
        .padding(.bottom,layout.safeBottom)
        .frame(width:layout.width,height:layout.footerHeight)
        .background(Color(red:1/255,green:8/255,blue:14/255).opacity(0.969))
        .overlay(alignment:.top) {
            Rectangle().fill(muted.opacity(0.42)).frame(height:1)
        }
        .accessibilityIdentifier("w3-startup-footer-bottom")
    }

    private func sourcePage(_ layout:W3AdaptiveViewport568)->some View {
        VStack(spacing:0) {
            sourceHeader(layout)
            GeometryReader { center in
                let scale=layout.sourceScale
                ZStack {
                    VStack(spacing:layout.compact ? 7 : 17) {
                        Text("NOWY SYSTEM NAWIGACJI")
                            .font(.system(size:17*scale,weight:.medium,
                                          design:.monospaced))
                            .foregroundStyle(gold)
                        if let logo=SourceW3Images568.pair?.logo {
                            Image(uiImage:logo).resizable().scaledToFit()
                                .frame(width:layout.centerLogoWidth)
                                .accessibilityHidden(true)
                        }
                        Text("ORBITAL NAVIGATION SYSTEM")
                            .font(.system(size:18*scale,weight:.medium,
                                          design:.monospaced))
                            .foregroundStyle(cyan)
                        TimelineView(.animation(minimumInterval:1.0/30.0,
                                     paused:stage != .waiting)) { timeline in
                            Button(action:proceed) {
                                Text("NACIŚNIJ ENTER / START")
                                    .font(.system(size:21*scale,weight:.semibold,
                                                  design:.monospaced))
                                    .foregroundStyle(
                                        Color(red:202/255,green:219/255,
                                              blue:224/255).opacity(
                                            W3StartupPolicy568.referencePromptAlpha(
                                                timeline.date.timeIntervalSinceReferenceDate)))
                                    .frame(minHeight:layout.compact ? 32 : 48)
                                    .frame(maxWidth:.infinity)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("w3-startup-enter")
                            .accessibilityLabel(
                                "Naciśnij Enter albo dotknij, aby wejść do menu")
                        }
                        Rectangle().fill(muted.opacity(0.7))
                            .frame(width:min(326,layout.width*0.45),height:1)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
                    .padding(.bottom,layout.compact ? 11 : 35)
                    VStack(spacing:0) {
                        Spacer(minLength:0)
                        HStack(spacing:8) {
                            Text("TERMINAL // SYNIXAD COMMAND")
                            Spacer(minLength:4)
                            Text("STATUS POŁĄCZENIA: AKTYWNY")
                        }
                        .font(.system(size:14*scale,design:.monospaced))
                        .foregroundStyle(muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .padding(.horizontal,layout.horizontalPadding)
                        .padding(.bottom,layout.compact ? 7 : 12)
                    }
                    .allowsHitTesting(false)
                }
                // Center content in the window's unobstructed region;
                // landscape Dynamic Island can occupy either edge.
                .frame(width:layout.usableWidth,height:center.size.height)
                .position(x:layout.safeLeft+layout.usableWidth/2,
                          y:center.size.height/2)
            }
            .frame(height:layout.contentHeight)
            sourceFooter(layout)
        }
        .frame(width:layout.width,height:layout.height)
    }

    var body:some View {
        GeometryReader { geo in
            let layout=W3AdaptiveViewport568(
                width:geo.size.width,height:geo.size.height,
                insets:safeInsets)
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
                    sourcePage(layout)
                }
                if stage != .waiting {
                    // Source reference shutter covers between the anchored
                    // header and footer. iPad 4:3 does not re-center bars.
                    Rectangle().fill(Color(red:4/255,green:16/255,
                                            blue:27/255).opacity(0.988))
                        .frame(width:geo.size.width * (stage == .cover
                            ? wipe : 1-wipe),
                               height:layout.contentHeight)
                        .position(
                            x:stage == .cover
                              ? geo.size.width*wipe/2
                              : geo.size.width*(wipe+(1-wipe)/2),
                            y:layout.headerHeight+layout.contentHeight/2)
                        .accessibilityHidden(true)
                }
                // Shield underlying menu input even while the curtain unveils.
                Color.clear.contentShape(Rectangle())
                    .allowsHitTesting(stage != .waiting)
            }
            .frame(width:geo.size.width,height:geo.size.height)
            .background {
                W3SafeAreaReader568(insets:$safeInsets)
                    .frame(width:0,height:0)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {proceed()}
        }
        .ignoresSafeArea()
        .focusable(true)
        .focused($keyboardFocused)
        .onKeyPress(.return) {proceed();return .handled}
        .onKeyPress(.space) {proceed();return .handled}
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
        pad.buttonMenu.pressedChangedHandler = {[weak self] _,_,pressed in
            if pressed {DispatchQueue.main.async {self?.action?()}}
        }
    }
    func stop() {
        for controller in configured {
            controller.extendedGamepad?.buttonA.pressedChangedHandler=nil
            controller.extendedGamepad?.buttonMenu.pressedChangedHandler=nil
        }
        configured.removeAll()
        subscriptions.forEach {NotificationCenter.default.removeObserver($0)}
        subscriptions.removeAll()
        action=nil
    }
    deinit {stop()}
}
