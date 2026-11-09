import Foundation

@main enum H55DockingPresentation580Tests {
    static func near(_ a:Float,_ b:Float)->Bool{abs(a-b)<0.0001}
    static func main() {
        let start=H55DockingPresentation580.camera(time:0)
        let end=H55DockingPresentation580.camera(time:3.25)
        precondition(near(start.x,0) && near(start.y,7.8) && near(start.z,40))
        precondition(near(end.y,6.8) && near(end.z,31))
        let ship0=H55DockingPresentation580.ship(time:0)
        let ship1=H55DockingPresentation580.ship(time:0.62)
        let ship3=H55DockingPresentation580.ship(time:3.25)
        precondition(near(ship0.y,1.05) && near(ship0.z,-11.5))
        precondition(near(ship1.z,-11.5),"ship must wait for original .62s")
        precondition(near(ship3.y,2.05) && near(ship3.z,0))
        precondition(near(ship3.yaw,65*Float.pi/180),
            "PC default HangarShipSpin551 is 20 degrees per second")
        precondition(H55DockingPresentation580.ship(time:.nan).z == ship0.z)
        precondition(H55DockingPresentation580.ship(time:1.2).z > -11.5)
        print("PASS H13-C PC580 docking camera + ship cinematic 3.25s exact samples")
    }
}
