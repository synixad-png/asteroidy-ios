import Foundation

/// Deterministic 60/30-Hz display-cadence test: not a physical iPhone GPU
/// benchmark. Real source shots, shaders, iPad code and SFX remain unchanged.
@main struct PhoneCombatResolution568Tests {
    static func main() {
        func check(_ ok:Bool,_ message:String) {
            precondition(ok,message)
        }
        var clock:Double=0
        func frames(_ count:Int,_ fps:Double,_ active:Bool,
                    policy:inout PhoneCombatResolution568) {
            for _ in 0..<count {
                clock+=1/fps
                policy.observe(at:clock,projectilesActive:active)
            }
        }

        var adaptive=PhoneCombatResolution568()
        let original=adaptive.drawablePixels(
            widthPoints:932,heightPoints:430,contentScale:3)
        check(original.width==2796 && original.height==1290,
              "iPhone 15 Pro Max exact native fullscreen 19.5:9")
        check(adaptive.drawableScale==1 &&
              adaptive.tier == .native,"iPhone begins at 100% quality")
        frames(600,60,true,policy:&adaptive)
        check(adaptive.tier == .native,
              "60fps continuous fire must retain 100% image quality")
        frames(10,30,true,policy:&adaptive)
        check(adaptive.tier == .native,
              "one third-second of misses must not cause quality flicker")
        frames(15,30,true,policy:&adaptive)
        check(adaptive.tier == .balanced && adaptive.drawableScale==0.84,
              "sustained 30fps fire enables balanced 84% framebuffer")
        let middle=adaptive.drawablePixels(
            widthPoints:932,heightPoints:430,contentScale:3)
        check(middle.width<original.width && middle.height<original.height,
              "balanced actually reduces GPU pixel area")
        frames(23,30,true,policy:&adaptive)
        check(adaptive.tier == .performance && adaptive.drawableScale==0.74,
              "still-30fps during shots advances to 74% framebuffer")
        let low=adaptive.drawablePixels(
            widthPoints:932,heightPoints:430,contentScale:3)
        check(low.width*low.height<middle.width*middle.height,
              "performance tier has fewer rasterized pixels")
        check(Double(low.width*low.height)/
              Double(original.width*original.height)<0.56,
              "worst tier reduces pixel area by about 45%")
        frames(120,60,true,policy:&adaptive)
        check(adaptive.tier == .performance,
              "full image quality must not oscillate mid-fire")
        frames(120,60,false,policy:&adaptive)
        check(adaptive.tier == .performance,
              "wait more than four stable seconds before upscaling")
        frames(140,60,false,policy:&adaptive)
        check(adaptive.tier == .balanced,
              "stable 60fps without shooting recovers one tier")
        frames(250,60,false,policy:&adaptive)
        check(adaptive.tier == .native,
              "stable calm recovers exact original resolution")
        check(adaptive.drawablePixels(widthPoints:932,heightPoints:430,
              contentScale:3).width==original.width,
              "resuming native must not change iPhone geometry/layout")

        var calm=PhoneCombatResolution568()
        clock=0
        frames(240,30,false,policy:&calm)
        check(calm.tier == .native,
              "never lower resolution without actual shot activity")
        var resumed=PhoneCombatResolution568()
        clock=0
        frames(13,30,true,policy:&resumed)
        clock+=5
        resumed.observe(at:clock,projectilesActive:true)
        frames(13,30,true,policy:&resumed)
        check(resumed.tier == .native,
              "lock/unlock or background stall must reset accumulator")
        let rotated=resumed.drawablePixels(
            widthPoints:430,heightPoints:932,contentScale:3)
        check(rotated.width==1290 && rotated.height==2796,
              "portrait/rotation recompute from current UIKit bounds")
        let invalid=resumed.drawablePixels(
            widthPoints:0,heightPoints:430,contentScale:3)
        check(invalid.width==0 && invalid.height==0,
              "do not allocate Metal targets for zero-sized UIKit view")
        print("PASS iPhone 60->30 shooting: hysteretic exact 100/84/74% drawable tiers")
        print("PASS 2796x1290 portrait/landscape, no oscillation, no touch/physics changes")
        print("LIMIT: iPhone hardware GPU FPS not measured by this test")
    }
}
