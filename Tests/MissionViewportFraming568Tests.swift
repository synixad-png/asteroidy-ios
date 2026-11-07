import Foundation

@main struct MissionViewportFraming568Tests {
    static func main() {
        var n=0
        func close(_ a:Float,_ b:Float,_ label:String) {
            precondition(a.isFinite && abs(a-b)<0.00001,label)
            n+=1
        }
        close(MissionViewportFraming568.sourceAspect,16.0/9.0,
              "original 1280x720 source aspect")
        let pc=MissionViewportFraming568.focals(
            aspect:16.0/9.0,sourceVerticalFocal:2)
        close(pc.vertical,2,"source vertical FOV never changes at 16:9")
        close(pc.horizontal,2/(16.0/9.0),
              "original Windows v568 horizontal FOV")
        let iphone=MissionViewportFraming568.focals(
            aspect:19.5/9.0,sourceVerticalFocal:2)
        close(iphone.vertical,2,"iPhone 19.5:9 visuals unmodified")
        close(iphone.horizontal,2/(19.5/9.0),
              "iPhone horizontal field follows real screen aspect")
        // Actual iPhone 15 Pro Max panel is 2796x1290 pixels;
        // SwiftUI landscape logical size is 932x430 points.
        // Full Metal scene fills the physical display; only UI is inset.
        let iphone15ProMax=MissionViewportFraming568.focals(
            aspect:932.0/430.0,sourceVerticalFocal:2)
        close(iphone15ProMax.vertical,pc.vertical,
              "iPhone 15 Pro Max wide display never stretches globe")
        close(iphone15ProMax.horizontal,2/(932.0/430.0),
              "19.5:9 must expose more horizontal scene than 16:9")
        precondition(iphone15ProMax.horizontal<pc.horizontal,
            "real iPhone 15 Pro Max scene expands horizontally, not crops")
        n+=1
        let ipad=MissionViewportFraming568.focals(
            aspect:4.0/3.0,sourceVerticalFocal:2)
        close(ipad.horizontal,pc.horizontal,
              "iPad 4:3 keeps original horizontal framing")
        close(ipad.vertical,1.5,
              "iPad 4:3 fits original 16:9 scene into available width")
        let ipadEleven=MissionViewportFraming568.focals(
            aspect:1.43,sourceVerticalFocal:2)
        close(ipadEleven.horizontal,pc.horizontal,
              "narrower iPad aspect maintains constant horizontal FOV")
        close(ipadEleven.vertical,2*1.43/(16.0/9.0),
              "iPad viewport frames from aspect not device identity")
        // Original sphere eye: GpuSphere67.cs:414 = 310; source outer
        // planet radius: GpuPlanetGltf463.cs = 100*1.4419674.
        // Atmosphere47's visible haze peak r≈1.055 must fit the iPad.
        let eye:Float=310/(100*1.4419674)
        let visibleLimb:Float=1.055
        let projected=ipad.vertical*visibleLimb /
            sqrt(eye*eye-visibleLimb*visibleLimb)
        precondition(projected<1 && projected>0.5,
                     "original atmosphere high-opacity limb must fit iPad")
        n+=1
        let narrower=MissionViewportFraming568.focals(
            aspect:1.0,sourceVerticalFocal:2)
        close(narrower.horizontal,pc.horizontal,
              "portrait-like width still fits original frame")
        let invalid=MissionViewportFraming568.focals(
            aspect:.nan,sourceVerticalFocal:2)
        close(invalid.vertical,2,"unknown aspect safe fallback")
        print("PASS \(n) source 1280x720 iPhone/iPad mission planet+glow framing checks")
    }
}
