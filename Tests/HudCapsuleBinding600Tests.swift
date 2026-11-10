import Foundation

@main enum HudCapsuleBinding600Tests {
    static func check(_ value:@autoclosure ()->Bool,_ message:String) {
        precondition(value(),message)
    }
    static func main() {
        var names=[String]()
        var samples=[Int:[Float]]()
        for i in 0..<3 {
            names.append(["DAMAGE_HULL_FLASH_SOCKET",
                          "DAMAGE_ARMOR_FLASH_SOCKET",
                          "DAMAGE_SHIELD_FLASH_SOCKET"][i])
            for bubble in 0..<24 {
                let id=names.count
                names.append("CAPSULE_\(i)_WATER_BUBBLE_\(bubble)_INDEPENDENT_DAMAGE_SAFE")
                samples[id]=[-1,0,1]
            }
        }
        guard let binding=HudCapsuleBinding600(nodeNames:names,translationX:samples)
        else {preconditionFailure("source names must bind")}
        check(binding.capsules.count==3,"exactly three source capsules")
        check(binding.capsules.allSatisfy{$0.bubbles.count==24},"24 bubbles each")
        let animated=[Float](repeating:0,count:names.count)
        let all=binding.visibleBubbles(levels:[1,1,1],animatedX:animated)!
        check(all.allSatisfy{$0},"all bubbles visible at full charge")
        let empty=binding.visibleBubbles(levels:[0,1,1],animatedX:animated)!
        check(binding.capsules[0].bubbles.allSatisfy{!empty[$0]},
              "empty hull hides only hull bubbles")
        check(binding.capsules[1].bubbles.allSatisfy{empty[$0]},
              "armor bubbles remain independent")
        let half=binding.visibleBubbles(levels:[0.5,1,1],animatedX:animated)!
        check(binding.capsules[0].bubbles.allSatisfy{half[$0]},
              "half hull permits bubbles left of cutoff")
        check(abs(binding.flashScale(channel:0,flash:1)!-0.751)<0.00001,
              "PC authored flash socket scale")
        check(HudCapsuleBinding600(nodeNames:Array(names.dropLast()),translationX:samples)==nil,
              "incomplete original GLB nodes rejected")
        print("PASS iOS HUD v600 GLB bubble node bindings and source masking")
    }
}
