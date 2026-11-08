import Foundation

@main struct H55Entry580Tests {
    typealias G=H55CollisionGeometry580
    typealias E=H55Entry580
    private static func check(_ value:Bool,_ note:String) {
        precondition(value,"H05: "+note)
    }
    static func main() {
        check(E.candidates.map{$0.x} == [2,3,-2,4,-4,6] &&
              E.candidates.map{$0.z} == [14,14,14,15,15,15],
              "six candidate coordinates are EXACT PC HubWalkPlaceAtEntry380")
        check(E.overhead == [0,0.55,1.15,4.50],
              "body and three headroom levels must be checked")
        check(E.arrivalSeconds==3.25,"original Hub90 arrival gate")
        var all=H55Arrival580(spawnClear:true)
        all.advance(dt:-5)
        check(all.time==0 && !all.walking,"no negative-time activation")
        all.advance(dt:1)
        check(abs(all.time-0.06)<0.00001,"source dt capped at 0.06s")
        for _ in 0..<53 {all.advance(dt:0.06)}
        check(all.arriving && !all.walking,"walking forbidden before 3.25s")
        all.advance(dt:0.06)
        check(!all.arriving && all.walking && all.started,
              "first source frame >=3.25 enables walking")
        all.advance(dt:0.06)
        check(all.walking,"no restart or disabling after arrival")
        var blocked=H55Arrival580(spawnClear:false)
        blocked.advance(dt:100)
        blocked.skip()
        blocked.advance(dt:0.06)
        check(blocked.started && !blocked.walking,
              "a rejected spawn never enables walking, even after skip")
        var skipped=H55Arrival580(spawnClear:true)
        skipped.skip()
        check(!skipped.walking && !skipped.arriving,
              "PC skip arrival updates timer only")
        skipped.advance(dt:0.001)
        check(skipped.walking,"PC StepHub90 starts walking after skip")
        // A separate, physically-valid floor at (2,14) must win.
        // The original spawn list is never reordered for nearest-to-center.
        let floor:[Float]=[
            0,0.1,10, 8,0.1,10, 0,0.1,18,
            8,0.1,10, 8,0.1,18, 0,0.1,18
        ]
        let geometry=G.Geometry(triangles:floor,objects:[],
            sourceTriangles:2,proxyTriangles:0,sceneNodes:1,
            minX:-30,maxX:52,minZ:-20,maxZ:20)
        let collision=H55SpatialSupport580(geometry:geometry)
        guard let place=E.find(using:collision) else {
            preconditionFailure("H05 did not find valid first source point")
        }
        check(place.x==2 && place.z==14 && abs(place.feet-0.1)<0.0001,
              "choose FIRST source candidate with exact floor and 4 headrooms")
        let notFloor=G.Geometry(triangles:[],objects:[],
            sourceTriangles:0,proxyTriangles:0,sceneNodes:1,
            minX:-30,maxX:52,minZ:-20,maxZ:20)
        check(E.find(using:H55SpatialSupport580(geometry:notFloor))==nil,
              "no fabricated 0,12.5 fallback if all source candidates fail")
        var roof=G.Box(name:"HL_IMPORT_TEST")
        roof.expand(1.6,4.6,13.6)
        roof.expand(2.4,6.0,14.4)
        let blockedRoof=G.Geometry(triangles:floor,objects:[roof],
             sourceTriangles:2,proxyTriangles:0,sceneNodes:1,
             minX:-30,maxX:52,minZ:-20,maxZ:20)
        let lowerCandidate=E.find(using:H55SpatialSupport580(geometry:blockedRoof))
        check(lowerCandidate?.x==3 && lowerCandidate?.z==14,
              "headroom at +4.50 rejects first candidate and uses second")
        print("PASS H05 exact six-source entry, four headrooms, no fallback, 3.25s cap/skip and fail-closed walking")
    }
}
