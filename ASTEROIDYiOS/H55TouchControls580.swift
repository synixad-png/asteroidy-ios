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

    @State private var rightLast:CGSize = .zero

    private let borderColor=Color(red:0.29,green:0.75,blue:0.83)
    private let textColor=Color(red:0.94,green:0.79,blue:0.51)

    var body:some View {
        GeometryReader { geometry in
            let w=geometry.size.width
            let h=geometry.size.height
            let compact=h<390
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

                // Two invisible full-screen gesture zones, no thumbsticks.
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
            rightLast = .zero
        }
    }

    private var walkGesture:some Gesture {
        DragGesture(minimumDistance:0)
            .onChanged { value in
                let v=H55TouchMapping580.walk(
                    dx:Float(value.translation.width),
                    dy:Float(value.translation.height))
                onWalk(v.forward,v.right)
            }
            .onEnded { _ in
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
            }
            .onEnded { _ in
                rightLast = .zero
            }
    }

}
