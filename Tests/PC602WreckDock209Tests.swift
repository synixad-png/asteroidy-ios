import Foundation

// GOLDEN SOURCE: PC v602 GpuAmbient37.cs SpaceHash207/SpaceRand207;
// GpuIntro41.cs DrawDetailedResearchWreck211(211,true), lines 398-415,
// DrawOrbitResearchWreck209 31deg/-9deg/scale=.504*1.20.
// Gate/navigation from Hub90.cs 34-68; no actual H55 scene simulation.
func close(_ a:Float,_ b:Float,_ tolerance:Float,_ why:String) {
    assert(a.isFinite && abs(a-b)<=tolerance,
           "\(why): received \(a), source v602 expected \(b)")
}
func distance(_ p:SIMD3<Float>)->Float {
    sqrt(p.x*p.x+p.y*p.y+p.z*p.z)
}
guard CommandLine.arguments.count==2 else {
    fatalError("Supply SHA-verified PC602Home290HeightMap.bin")
}
let home=try PC602NewHome290(heightMapBytes:Data(
    contentsOf:URL(fileURLWithPath:CommandLine.arguments[1])))
guard let dock=home.wreckPosition() else {
    fatalError("The source docking wreck must use the original H290 relief")
}
let fragments=PC602WreckDebris209.fragments()
assert(PC602WreckDebris209.primaryCount==146)
assert(fragments.filter{!$0.isAccent}.count==146)
assert(fragments.filter{$0.isAccent}.count==15)
assert(fragments.count==161)
assert(fragments.filter{$0.originalIndex==0}.count==2)
assert(fragments.filter{$0.originalIndex==145}.count==1)
assert(fragments.allSatisfy{f in
    f.localSize.x>0 && f.localSize.y>0 && f.localSize.z>0 &&
    f.localCenter.x.isFinite && f.localCenter.y.isFinite &&
    f.localCenter.z.isFinite && f.color.w==1
})
close(PC602WreckDebris209.spaceRand207(211,0,8),
      0.109621115,0.000002,"PC602 source SpaceHash207 first x jitter")
close(PC602WreckDebris209.spaceRand207(211,0,14),
      0.980969965,0.000002,"PC602 source first y jitter")
close(PC602WreckDebris209.spaceRand207(211,0,55),
      0.397871763,0.000002,"PC602 source first radius jitter")
let first=fragments.first(where:{$0.originalIndex==0 && !$0.isAccent})!
close(first.localCenter.x,17.267347,0.0003,"first PC wreck box x")
close(first.localCenter.y,7.348033,0.0003,"first PC wreck box y")
close(first.localCenter.z,8.816133,0.0003,"first PC wreck box z")
close(first.localSize.x,2.391913,0.0003,"first source radius")
close(first.localSize.y,2.391913*1.12,0.0003,"source debris size y")
close(first.localSize.z,2.391913*1.28,0.0003,"source debris size z")
close(first.color.x,0.78,0.00001,"hot source debris red")
close(first.color.y,0.42,0.00001,"hot source debris green")
close(first.color.z,0.14,0.00001,"hot source debris blue")
let last=fragments.last(where:{$0.originalIndex==145})!
close(last.localCenter.x,191.60283,0.0003,"last PC wreck box x")
close(last.localCenter.y,31.55221,0.0003,"last PC wreck box y")
close(last.localCenter.z,38.12467,0.0003,"last PC wreck box z")
close(last.localSize.x,1.6708254,0.0003,"last source radius")
// PC602 WreckBox209: six original faces, each 2 triangles, no reversed
// surfaces or missing back side. This checks source structure independently
// of the still-pending grime/scratch/contour stage and whole-hull model.
let boxFaces=PC602WreckDebris209.structuralBoxFaces()
assert(boxFaces.count==161*36)
assert(boxFaces.count/3==1932)
let box0=Array(boxFaces.prefix(36))
close(box0[0].position.x,first.localCenter.x-first.localSize.x/2,
      0.00001,"source face +Z first vertex X")
close(box0[0].position.y,first.localCenter.y-first.localSize.y/2,
      0.00001,"source face +Z first vertex Y")
close(box0[0].position.z,first.localCenter.z+first.localSize.z/2,
      0.00001,"source face +Z first vertex Z")
assert(box0[0].normal==SIMD3<Float>(0,0,1))
assert(box0[6].normal==SIMD3<Float>(0,0,-1))
assert(box0[12].normal==SIMD3<Float>(0,-1,0))
assert(box0[18].normal==SIMD3<Float>(0,1,0))
assert(box0[24].normal==SIMD3<Float>(-1,0,0))
assert(box0[30].normal==SIMD3<Float>(1,0,0))
close(box0[6].tint.x,first.color.x*0.86,
      0.00001,"source WreckBox209 back face red attenuation")
close(box0[12].tint.z,first.color.z*0.97,
      0.00001,"source WreckBox209 bottom face blue attenuation")
assert(boxFaces.allSatisfy{ v in
    v.position.x.isFinite && v.position.y.isFinite &&
    v.position.z.isFinite && v.tint.w==1
})

guard let worldFaces=PC602WreckDebris209.worldStructuralFaces(home:home)
else {fatalError("Original source world triangles cannot be emitted")}
assert(worldFaces.count==boxFaces.count)
for index in [0,6,12,18,24,30,35,boxFaces.count-1] {
    close(distance(worldFaces[index].position -
        PC602WreckDebris209.worldPosition(boxFaces[index].position,
                                           dock:dock)),
        0,0.0003,"every source wreck face must share dock center + rotations")
    close(distance(worldFaces[index].normal),1,0.00001,
          "GL modelview-rotated wreck face normal")
}
assert(worldFaces.allSatisfy { v in
    v.position.x.isFinite && v.position.y.isFinite &&
    v.position.z.isFinite && v.normal.x.isFinite && v.normal.z.isFinite
})
let accent=fragments.first(where:{$0.isAccent && $0.originalIndex==0})!
close(accent.localCenter.x,first.localCenter.x+first.localSize.x*0.9,
      0.00002,"source accent x")
close(accent.localSize.y,first.localSize.x*1.45,
      0.00002,"source accent height")
close(PC602WreckDebris209.scale,0.6048,0.000001,
      "v295 wreck enlarged scale")
close(PC602NewHome290.dockRadius295,43.2,0.00001,
      "v295 exactly 43.2m docking circle")
close(distance(PC602WreckDebris209.worldPosition(
    SIMD3<Float>(repeating:0),dock:dock)-dock),
    0,0.00001,"wreck mesh shares TRUE docking origin")
guard let world=PC602WreckDebris209.worldFragments(home:home)
else {fatalError("Original source docking point absent")}
assert(world.count==161)
close(distance(world[0].localCenter -
    PC602WreckDebris209.worldPosition(first.localCenter,dock:dock)),
    0,0.0001,"source GL transform order yaw/roll/scale")
close(world[0].localSize.x,first.localSize.x*0.6048,
      0.00001,"debris units follow parent source model")

let equipment=PC602HomeFlight291.Equipment(craft:.vanguard)!
let flight=try PC602HomeFlight291(home:home,equipment:equipment)
let eligible=PC602HomeFlight291.DockContext(
    planetHub:true,orbitMode:true)
var orbit=PC602HomeHubRoute90()
assert(orbit.location == .orbit)
assert(!orbit.enterFromOrbit(flight,context:eligible),
       "Starting near sector 1 does not magically reach the wreck")
assert(!orbit.enterFromOrbit(distance:43.201,miningDetached:false,
                             context:eligible))
assert(orbit.enterFromOrbit(distance:43.2,miningDetached:false,
                            context:eligible))
assert(orbit.mustDisplayPhysicalH55)
assert(orbit.returnsToOrbitOnExit)
assert(orbit.mayCaptureOrbitResumeOnExit)
assert(!orbit.enterFromOrbit(distance:0,miningDetached:false,context:eligible),
       "Do not re-enter a second H55 instance from inside H55")
assert(orbit.exitHangar() == .orbit)
assert(orbit.location == .orbit)
assert(orbit.exitHangar() == nil)
assert(orbit.transitions==2)
assert(!orbit.enterFromOrbit(distance:0,miningDetached:true,context:eligible))
assert(!orbit.enterFromOrbit(distance:0,miningDetached:false,
       context:.init(planetHub:false,orbitMode:true)))
assert(!orbit.enterFromOrbit(distance:0,miningDetached:false,
       context:.init(planetHub:true,orbitMode:false)))
assert(!orbit.enterFromOrbit(distance:0,miningDetached:false,
       context:.init(planetHub:true,orbitMode:true,sceneBusy:true)))
assert(!orbit.enterFromOrbit(distance:0,miningDetached:false,
       context:.init(planetHub:true,orbitMode:true,talentOpen:true)))

var menu=PC602HomeHubRoute90(start:.menu)
assert(!menu.enterFromMenu(sceneBusy:true))
assert(menu.enterFromMenu(sceneBusy:false))
assert(!menu.returnsToOrbitOnExit)
assert(!menu.mayCaptureOrbitResumeOnExit)
assert(menu.mustDisplayPhysicalH55)
assert(menu.exitHangar() == .menu)
assert(menu.location == .menu)
assert(!menu.mustDisplayPhysicalH55)
assert(menu.transitions==2)
assert(!menu.enterFromOrbit(distance:0,miningDetached:false,context:eligible))
print("PASS PC602 original 146+15 wreck debris, hash, world alignment and " +
      "1932 original box triangles and Hub90 dock/menu/H55 routing; no invented GLB or IPA claim")
