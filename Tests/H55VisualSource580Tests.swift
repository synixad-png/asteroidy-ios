import Foundation
@main enum H55VisualSource580Tests {
    static func main() {
        func check(_ value:Bool,_ reason:String){precondition(value,reason)}
        check(H55VisualSource580.isGlassPane(node:"MECHANIC_01 / glass",material:"glass"),"PC opaque glass")
        check(H55VisualSource580.isGlassPane(node:"H43_SLIDING_DOOR_TINTED_GLASS",material:"H45_SAFETY_GLASS_DOOR"),"H45 tinted glass")
        check(H55VisualSource580.isGlassPane(node:"HANGARLAB_PREFAB_2504_glasswall__LAB20_GLASSWALL_SZKLO_LAMINOWANE_0_1",material:"LABv18_glass"),"glasswall pane")
        check(!H55VisualSource580.isGlassPane(node:"HANGARLAB_PREFAB_2504_glasswall__LAB20_GLASSWALL_RAMKA_DOLNA_0_2",material:"LABv20_machine_edge"),"frame stays opaque")
        check(!H55VisualSource580.isGlassPane(node:"HANGARLAB_PREFAB_2504_glasswall__LAB20_GLASSWALL_ZAMOCOWANIE_0_0.22_6",material:"LABv20_machine_edge"),"hardware stays opaque")
        check(H55VisualSource580.isTexturedCeiling(node:"05_ceiling / graphite",material:"H34_CEILING__graphite"),"textured ceiling")
        check(!H55VisualSource580.isTexturedCeiling(node:"GIANT_REPAIR_ARM_03_CEILING / JOINT_4",material:"H34_CEILING__graphite"),"crane unchanged")
        check(H55VisualSource580.lampEmission("H46_MAT_COLD_CYAN_EMISSIVE")?.b == 0.9,"source emitter")
        check(H55VisualSource580.lampEmission("H34_CEILING__graphite")==nil,"roof does not glow")
        let proxies=["H46_GENERAL_SPOT_01_KHR_SPOT","H46_WORK_SPOT_05_KHR_SPOT","H46_SCAN_SPOT_09_KHR_SPOT","H46_DOCK_01_RED_POINT_LIGHT","H46_UPPER_RED_-1_1_POINT"]
        check(proxies.allSatisfy{H55VisualSource580.lightProxy($0) != nil},"source fallback lights")
        check(H55VisualSource580.lightProxy("H46_DOCK_01_RED_BEACON_ANIMATED")==nil,"bulb mesh is not a point light")
        print("PASS PC580 source glass/ceiling/H46 source rules and hardware exclusions")
    }
}
