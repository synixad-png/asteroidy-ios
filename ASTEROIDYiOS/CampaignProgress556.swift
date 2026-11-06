import Foundation

// Faithful progress/unlock rules from ASTEROIDY v556 Windows/src/Orbit50.cs.
// An atlas entry does NOT imply that the corresponding mission has been ported.
struct CampaignProgress556: Equatable {
    static let missionCount = 26
    static let validMask = (1 << missionCount) - 1
    private(set) var completedMask: Int = 0
    private(set) var selectedSector: Int = 1

    init(mask: Int = 0, selectedSector: Int = 1) {
        completedMask = mask & Self.validMask
        self.selectedSector = (1...Self.missionCount).contains(selectedSector) ? selectedSector : 1
    }
    func completed(_ sector: Int) -> Bool {
        (1...Self.missionCount).contains(sector) && (completedMask & (1 << (sector - 1))) != 0
    }
    func unlocked(_ sector: Int) -> Bool {
        guard (1...Self.missionCount).contains(sector) else { return false }
        return sector == 1 || completed(sector) || completed(sector == 26 ? 24 : sector - 1)
    }
    var completedCount: Int {
        (1...Self.missionCount).reduce(0) { $0 + (completed($1) ? 1 : 0) }
    }
    var nextAvailableSector: Int {
        (1...Self.missionCount).first(where: { unlocked($0) && !completed($0) }) ?? 1
    }
    @discardableResult mutating func select(_ sector: Int) -> Bool {
        guard (1...Self.missionCount).contains(sector) else { return false }
        selectedSector = sector
        return true
    }
    /// PC Orbit50.OrbitClick51 selects only MissionUnlocked50.
    /// Selection never changes completion bits, rewards or unlocks.
    @discardableResult mutating func selectUnlocked(_ sector: Int) -> Bool {
        guard unlocked(sector) else { return false }
        selectedSector = sector
        return true
    }
    @discardableResult mutating func finishMission(_ sector: Int) -> Bool {
        guard (1...Self.missionCount).contains(sector), unlocked(sector), !completed(sector) else { return false }
        completedMask |= 1 << (sector - 1)
        return true
    }
    // Legacy planet-progress50.txt decimal bitmask; bit 26 aliases sector 1.
    static func readLegacyProgress(_ text: String) -> CampaignProgress556? {
        guard let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)), value >= 0 else { return nil }
        let bits = (value & validMask) | ((value & (1 << 26)) != 0 ? 1 : 0)
        return CampaignProgress556(mask: bits)
    }
}
enum CampaignStore556 {
    private static let key = "asteroidy.ios.v556.campaign.completedMask"
    // iOS-only UI restoration of OrbitTarget50, never mission completion.
    private static let selectedKey = "asteroidy.ios.v568.campaign.selectedSector"
    static func load(defaults: UserDefaults = .standard) -> CampaignProgress556 {
        var result = CampaignProgress556(mask: defaults.integer(forKey: key))
        let stored = defaults.integer(forKey: selectedKey)
        if !result.selectUnlocked(stored) {
            _ = result.selectUnlocked(result.nextAvailableSector)
        }
        return result
    }
    static func save(_ progress: CampaignProgress556, defaults: UserDefaults = .standard) {
        defaults.set(progress.completedMask, forKey: key)
        // Never store a locked selection through the public selection flow.
        defaults.set(progress.unlocked(progress.selectedSector)
                     ? progress.selectedSector : progress.nextAvailableSector,
                     forKey: selectedKey)
    }
}
