import Foundation

/// H10 is a literal port of PC v580 Windows/src/Hub90.cs HubNpcInteract526.
/// There is ONE authored exchange in that source, not a dialogue tree.
/// Other hangar panels/legacy Mechanic93 are deliberately separate (H11).
struct H55NpcDialogue580 {
    enum Transition:Equatable {case ignored,opened,closed}
    static let radius:Float=2.7
    static let spokenLine="WSZYSTKO W PORZĄDKU."
    // Literal PC strings are retained as source labels, including controls.
    static let openNotice="MECHANIK: WSZYSTKO W PORZADKU. E / ENTER / ESC - ZAKONCZ ROZMOWE."
    static let closeNotice="MECHANIK: DO ZOBACZENIA."

    private(set) var isOpen=false
    private(set) var finished=0
    private(set) var notice=""

    static func inRange(playerX:Float,playerZ:Float,
                        npcX:Float,npcZ:Float)->Bool {
        guard playerX.isFinite && playerZ.isFinite &&
              npcX.isFinite && npcZ.isFinite else{return false}
        return hypot(playerX-npcX,playerZ-npcZ)<=radius
    }

    /// PC v580 gates on current Hub90 mode, completed 3.25s arrival and
    /// active walk. While open, closing is allowed even if the NPC moves.
    /// On a successful CLOSE, increment the single source conversation
    /// counter exactly once. Only H08 may later activate a patrol.
    mutating func interact(walking:Bool,playerX:Float,playerZ:Float,
                           npcX:Float,npcZ:Float)->Transition {
        guard walking else{return .ignored}
        if isOpen {
            isOpen=false
            finished+=1
            notice=Self.closeNotice
            return .closed
        }
        guard Self.inRange(playerX:playerX,playerZ:playerZ,
                           npcX:npcX,npcZ:npcZ) else{return .ignored}
        isOpen=true
        notice=Self.openNotice
        return .opened
    }

    mutating func reset(){
        isOpen=false
        finished=0
        notice=""
    }
}
