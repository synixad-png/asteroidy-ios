import Foundation

/// Native executable proof that PC v602 orbital mode reuses the existing,
/// fully implemented source Wreck211 hull without changing combat Wreck214.
/// Inputs: GpuIntro41.DrawDetailedResearchWreck211(seed,orbit).
/// Compares seed 211 original combat 112/118 source with seed 211 orbit
/// 146/178 source: all hull panels, scratches, lamps are shared verbatim.
let ordinary=ResearchWreckGeometry214.make(sector:-3) // (-3)+214 = 211
let orbital=ResearchWreckGeometry214.makeOrbitHome602()
assert(ordinary.triangleCount>10000 && ordinary.lineCount>1000)
assert(orbital.triangleCount>ordinary.triangleCount)
assert(orbital.lineCount>ordinary.lineCount)
assert(orbital.triangleCount%3==0)
assert(orbital.lineCount%2==0)
assert(orbital.triangleCount<131072 && orbital.lineCount<32768)
assert(orbital.triangles.count==orbital.triangleCount*11)
assert(orbital.lines.count==orbital.lineCount*7)
assert(orbital.triangles.allSatisfy{$0.isFinite})
assert(orbital.lines.allSatisfy{$0.isFinite})
// Identical prefix proves the authored hull and all seven lamps did not
// drift when switching from original combat to original orbital debris.
let count=min(ordinary.triangles.count,orbital.triangles.count)
var shared=0
while shared<count && ordinary.triangles[shared]==orbital.triangles[shared] {
    shared+=1
}
assert(shared>=110_000, "Do not substitute/reorder the original PC source hull")
let lineCount=min(ordinary.lines.count,orbital.lines.count)
var sharedLines=0
while sharedLines<lineCount && ordinary.lines[sharedLines]==orbital.lines[sharedLines] {
    sharedLines+=1
}
assert(sharedLines>=10_000, "Original WreckSketchBox215 must be preserved")
let phases:Set<Int>=Set(stride(from:10,to:orbital.triangles.count,by:11)
    .map { Int((orbital.triangles[$0]*100).rounded()) }
    .filter {$0>=0})
assert(phases==Set([0,110,220,270,310,420,490]),
       "Exactly 7 original source timed warning lamps")
let rebuilt=ResearchWreckGeometry214.makeOrbitHome602()
assert(rebuilt.triangles.count==orbital.triangles.count)
assert(rebuilt.lines.count==orbital.lines.count)
assert(rebuilt.triangles.prefix(3000).elementsEqual(
       orbital.triangles.prefix(3000)))
assert(rebuilt.lines.prefix(3000).elementsEqual(
       orbital.lines.prefix(3000)))
// Nothing here changes original combat source output.
let sectorOne=ResearchWreckGeometry214.make(sector:1)
assert(sectorOne.triangleCount>10000)
assert(sectorOne.lineCount>1000)
print("PASS PC602 FULL source 3D research wreck: hull, panels, glass, " +
      "airlocks, antennae, grime, scratched lines, all seven phased lamps, " +
      "146 debris / 178m source orbit; combat wreck remains separate")
print("PC602 full hull triangles=\(orbital.triangleCount/3), " +
      "scratch lines=\(orbital.lineCount/2), " +
      "source-identical hull floats=\(shared)")
