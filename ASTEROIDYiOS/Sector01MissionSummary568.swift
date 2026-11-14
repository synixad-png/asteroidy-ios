import Foundation

/// Windows v568 LevelSummary166.cs + Game.FinishLevel() (Level 1, no boss).
/// A result may be constructed ONLY after CarbonisCombat568 reaches its
/// source Game.Step / FinishLevel guard. Creating a summary never saves or
/// unlocks the campaign; completion is committed by the owning GameView.
struct Sector01MissionSummary568: Equatable {
    let sector:Int
    let rocksDestroyed:Int
    let enemiesDestroyed:Int
    let scoreGained:Int
    let collectedTokens:Int
    let clearBonus:Int
    let earnedTokens:Int
    let isReplay:Bool
    let elapsedSeconds:Float

    /// LevelSummary166: SummaryPickups = LevelEarned - ClearBonus, no boss.
    /// Windows Game.FinishLevel: Level1 ClearBonus=10+Level*2=12 for
    /// eligible missions; replay does not award earnings.
    static func completedFirstMission(
        rocks:Int,enemies:Int,score:Int,lootTokens:Int,
        replay:Bool,elapsed:Float) -> Self {
        completedSourceMission(sector:1,rocks:rocks,enemies:enemies,
                               score:score,lootTokens:lootTokens,
                               replay:replay,elapsed:elapsed)
    }

    /// Game.FinishLevel: 10+level*2 on a first clear, no reward on replay.
    /// The caller alone persists campaign progression after actual combat.
    static func completedSourceMission(
        sector:Int,rocks:Int,enemies:Int,score:Int,lootTokens:Int,
        replay:Bool,elapsed:Float) -> Self {
        let pickupReward=replay ? 0 : max(0,lootTokens)
        let bonus=replay ? 0 : 10+sector*2
        return Self(sector:sector,rocksDestroyed:max(0,rocks),
                    enemiesDestroyed:max(0,enemies),
                    scoreGained:max(0,score),
                    collectedTokens:pickupReward,
                    clearBonus:bonus,
                    earnedTokens:pickupReward+bonus,
                    isReplay:replay,elapsedSeconds:max(0,elapsed))
    }
}
