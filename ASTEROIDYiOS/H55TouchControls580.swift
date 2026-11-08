import SwiftUI

/// Landscape H55 only. The complete LEFT half walks/strafe and the complete
/// RIGHT half looks; these touch domains are not shared with gameplay flight.
/// Jump and interact are explicit hit targets, comfortably inside the edges.
struct H55TouchControls580:View {
    var onWalk:(Float,Float)->Void
    var onLook:(Float,Float)->Void
    var onJump:()->Void
    var onTalk:()->Void
    var canTalk:Bool
    var conversationOpen:Bool
    var mechanicStatus:String

    @State private var walkTranslation:CGSize = .zero
    @State private var rightLast:CGSize = .zero
    @State private var walking=false
    @State private var looking=false

    private let borderColor=Color(red:0.29,green:0.75,blue:0.83)
    private let textColor=Color(red:0.94,green:0.79,blue:0.51)

    var body:some View {
        GeometryReader { geometry in
            let w=geometry.size.width
            let h=geometry.size.height
            let compact=h<390
            let controlSize:CGFloat=compact ? 102 : 128
            let buttonWidth:CGFloat=compact ? 104 : 124
            let buttonHeight:CGFloat=compact ? 43 : 51
            ZStack(alignment:.topLeading) {
                HStack(spacing:0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(walkGesture)
                        .accessibilityLabel("Lewa połowa: ruch przód tył i strafing")
                        .accessibilityIdentifier("h55-v580-left-walk")
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(lookGesture)
                        .accessibilityLabel("Prawa połowa: rozglądanie góra dół lewo prawo")
                        .accessibilityIdentifier("h55-v580-right-look")
                }
                .frame(width:w,height:h)

                // Read-only guidance can never steal touch input.
                walkIndicator(size:controlSize)
                    .position(x:w*0.20,y:h*0.68)
                    .allowsHitTesting(false)
                lookIndicator(size:controlSize)
                    .position(x:w*0.77,y:h*0.56)
                    .allowsHitTesting(false)

                Button(action:onTalk) {
                    Text("ROZMAWIAJ")
                        .font(.system(size:compact ? 11:13,weight:.bold,design:.monospaced))
                        .frame(width:buttonWidth,height:buttonHeight)
                        .foregroundStyle(canTalk || conversationOpen ? textColor : .gray)
                        .background(Color.black.opacity(0.78))
                        .overlay(RoundedRectangle(cornerRadius:8)
                            .stroke(borderColor.opacity(canTalk || conversationOpen ? 0.9:0.32),lineWidth:1))
                        .clipShape(RoundedRectangle(cornerRadius:8))
                }
                .buttonStyle(.plain)
                .disabled(!canTalk && !conversationOpen)
                .position(x:w*0.33,y:h*0.79)
                .accessibilityIdentifier("h55-v580-npc-interact")

                Button(action:onJump) {
                    Text("SKOK")
                        .font(.system(size:compact ? 12:14,weight:.bold,design:.monospaced))
                        .frame(width:buttonWidth,height:buttonHeight)
                        .foregroundStyle(textColor)
                        .background(Color.black.opacity(0.78))
                        .overlay(RoundedRectangle(cornerRadius:8)
                            .stroke(borderColor.opacity(0.9),lineWidth:1))
                        .clipShape(RoundedRectangle(cornerRadius:8))
                }
                .buttonStyle(.plain)
                .position(x:w*0.84,y:h*0.79)
                .accessibilityIdentifier("h55-v580-jump")

                Text(mechanicStatus)
                    .font(.system(size:compact ? 9:11,weight:.semibold,design:.monospaced))
                    .foregroundStyle(textColor)
                    .padding(.horizontal,9)
                    .padding(.vertical,5)
                    .background(Color.black.opacity(0.62))
                    .position(x:w*0.33,y:h*0.10)
                    .allowsHitTesting(false)
            }
            .frame(width:w,height:h)
            .clipped()
        }
        .onDisappear {
            onWalk(0,0)
            walkTranslation = .zero
            rightLast = .zero
            walking=false
            looking=false
        }
    }

    private var walkGesture:some Gesture {
        DragGesture(minimumDistance:0)
            .onChanged { value in
                walkTranslation=value.translation
                walking=true
                let v=H55TouchMapping580.walk(
                    dx:Float(value.translation.width),
                    dy:Float(value.translation.height))
                onWalk(v.forward,v.right)
            }
            .onEnded { _ in
                walkTranslation = .zero
                walking=false
                onWalk(0,0)
            }
    }

    private var lookGesture:some Gesture {
        DragGesture(minimumDistance:0)
            .onChanged { value in
                // Incremental mouse-look (no spring-to-centre or inverted axis).
                // Multi-touch is independent: LEFT keeps moving during RIGHT look.
                let dx=Float(value.translation.width-rightLast.width)
                let dy=Float(value.translation.height-rightLast.height)
                onLook(dx,dy)
                rightLast=value.translation
                looking=true
            }
            .onEnded { _ in
                rightLast = .zero
                looking=false
            }
    }

    private func walkIndicator(size:CGFloat)->some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.36))
                .overlay(Circle().stroke(borderColor.opacity(0.52),lineWidth:1.4))
            Text("↑")
                .offset(y:-size*0.32)
            Text("↓")
                .offset(y:size*0.32)
            Text("←")
                .offset(x:-size*0.32)
            Text("→")
                .offset(x:size*0.32)
            Circle()
                .fill(borderColor.opacity(walking ? 0.46 : 0.21))
                .frame(width:size*0.31,height:size*0.31)
                .offset(x:walkTranslation.width*0.32,y:walkTranslation.height*0.32)
                .mask(Circle().frame(width:size*0.85,height:size*0.85))
        }
        .font(.system(size:14,weight:.bold))
        .foregroundStyle(borderColor)
        .frame(width:size,height:size)
        .overlay(alignment:.bottom) {
            Text("CHODZENIE / STRAFE")
                .font(.system(size:9,weight:.semibold,design:.monospaced))
                .foregroundStyle(textColor)
                .offset(y:19)
        }
    }

    private func lookIndicator(size:CGFloat)->some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.21))
                .overlay(Circle().stroke(borderColor.opacity(looking ? 0.64 : 0.37),lineWidth:1))
            Image(systemName:"viewfinder")
                .font(.system(size:size*0.30,weight:.ultraLight))
                .foregroundStyle(borderColor.opacity(0.8))
        }
        .frame(width:size*0.68,height:size*0.68)
        .overlay(alignment:.bottom) {
            Text("ROZGLĄDANIE")
                .font(.system(size:9,weight:.semibold,design:.monospaced))
                .foregroundStyle(textColor)
                .offset(y:22)
        }
    }
}
