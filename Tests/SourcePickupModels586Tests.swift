import Foundation

@main enum SourcePickupModels586Tests {
    static func main() {
        let kinds=SourcePickupModels586.Kind.allCases
        precondition(kinds.count==4)
        precondition(Set(kinds.map(\.fileName)).count==4)
        let expected:[(SourcePickupModels586.Kind,Int,Int,Float)]=[
            (.shield,478_320,60,30),(.boost,502_996,78,26),
            (.energy,506_076,78,26),(.bomb,483_424,78,26)
        ]
        for (kind,bytes,scale,base) in expected {
            precondition(kind.byteCount==bytes)
            precondition(kind.defaultVisualPercent==scale)
            precondition(kind.sourceBaseSize==base)
            precondition(kind.sha256.count==64)
            for name in kind.sourceSupplyNames {
                precondition(SourcePickupModels586.kind(forSourceSupplyName:name)==kind)
                precondition(SourcePickupModels586.kind(forSourceSupplyName:name,trophy:true)==nil)
            }
        }
        precondition(SourcePickupModels586.kind(forSourceSupplyName:"Token")==nil)
        precondition(SourcePickupModels586.kind(forSourceSupplyName:"Flame")==nil)
        print("PASS: four original GLB identities and PC Supply mapping")
    }
}
