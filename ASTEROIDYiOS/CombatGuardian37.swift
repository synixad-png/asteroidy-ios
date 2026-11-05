import Foundation

/// Exact one-hit protection from Windows/src/Campaign37.cs TryGuardian().
/// The drone's flight, target acquisition and plasma weapon (Game.cs
/// StepGuardian298) are separate and are not claimed to be ported here.
final class CombatGuardian37 {
    let owned:Bool
    private(set) var charges:Int

    init(owned:Bool=false) {
        self.owned=owned
        charges=owned ? 1 : 0
    }

    /// Game.StartLevel / Game.FinishLevel replenish one interceptor
    /// whenever GuardianOwned is set. No charges if no guardian is owned.
    func resetForSector() {
        charges=owned ? 1 : 0
    }

    /// TryGuardian(): consume one charge, grant 1.2s invulnerability.
    @discardableResult
    func absorb(invincible:inout Float) -> Bool {
        guard charges>0 else {return false}
        charges -= 1
        invincible=1.2
        return true
    }
}
