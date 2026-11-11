import Foundation

// Native, executable source tests for the real 820-PC602-stone binary.
// A separate Python audit checks its exact original subdivided vertex data.
guard CommandLine.arguments.count==3 else {
    fatalError("Usage: TestPC602Belt <H290HeightMap.bin> <PC602OrbitBelt51.bin>")
}
let height=try Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1]))
let home=try PC602NewHome290(heightMapBytes:height)
let source=try Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[2]))
let belt=try PC602OrbitBelt51(data:source)
assert(belt.stones.count==820)
assert(belt.vertexCount==1_259_520)
assert(belt.vertexOffset==16+820*28)
assert(belt.stones.filter{$0.vertexCount==3840}.count==164)
assert(belt.stones.filter{$0.vertexCount==960}.count==656)
assert(belt.sourcePlacementValid(home:home),
       "Original H290 flight shell: all 820 authored rocks must remain above terrain")
assert(belt.stones.first?.firstVertex==0)
assert(belt.stones.last!.firstVertex+belt.stones.last!.vertexCount==
       belt.vertexCount)

let identity:[Float]=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,-400,1]
let count=belt.stones.filter {
    belt.visible($0,view:identity,aspect:16.0/9.0)
}.count
assert(count>0 && count<=820)
let back:[Float]=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,400,1]
assert(!belt.stones.contains {
    belt.visible($0,view:back,aspect:16.0/9.0)
})
assert(!belt.visible(belt.stones[0],view:identity,aspect:0))
assert(!belt.visible(belt.stones[0],view:[],aspect:16.0/9.0))

do {
    _=try PC602OrbitBelt51(data:Data([66,48,53,49]))
    fatalError("The original 820-stone resource must not accept truncation")
} catch PC602OrbitBelt51.SourceError.badHeader {
    // Expected: source header alone is not an asteroid belt.
}
var mutated=source
mutated[12]=0
mutated[13]=0
mutated[14]=0
mutated[15]=0
do {
    _=try PC602OrbitBelt51(data:mutated)
    fatalError("Invalid source vertex count must be rejected")
} catch PC602OrbitBelt51.SourceError.invalidGeometry {
    // Expected
}
print("PASS PC602 source H290 + all 820 native Swift asteroid records; " +
      "source 419840 triangles, original LOD and frustum, malformed data rejected")
