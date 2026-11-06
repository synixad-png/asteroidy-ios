import Foundation

/// Source-audited v568 level labels, indexed 1...26.
/// Provenance: ASTEROIDY_v568_PLANETY_01_26.csv built from original
/// Windows/src/PlanetMesh.cs, Carbonis277.cs, GpuPlanetGltf463.cs and
/// source asset manifest. This is not a new mission or invented world.
enum MissionCatalog568 {
    static let planetNames: [String] = [
        "CARBONIS / PBR",
        "TITAN / GÓRY I ŚNIEG",
        "IGNIS / WULKANY",
        "AZURE / ARCHIPELAGI",
        "BOREAS / LODOWCE",
        "SAHARA / WYDMY",
        "MYCEL / LAS GRZYBÓW",
        "PRISM / KRYSZTAŁY",
        "AMBER / JESIENNY LAS",
        "MIRE / MOKRADŁA",
        "RUBRA / CZERWONE SKAŁY",
        "SALINA / SOLNE PUSTKOWIA",
        "NYX / BIOLUMINESCENCJA",
        "OBSIDIAN / IGŁY GÓRSKIE",
        "INFERNO / MAGMA",
        "REEF / KORALOWY OCEAN",
        "AURORA / FIOLETOWY LÓD",
        "AUREUM / ZŁOTE KANIONY",
        "SPORE / OGRODY ZARODNIKÓW",
        "JADE / SZMARAGDOWE IGŁY",
        "SCARLET / KARMINOWY LAS",
        "POLARIS / WIECZNY MRÓZ",
        "TOXIN / OBCY EKOSYSTEM",
        "SOL / ZŁOTA LAWA",
        "AMIGA / BOING BALL",
        "VULKARIS / OBCY ŚWIAT"
    ]
    static func title(for sector: Int) -> String? {
        guard (1...planetNames.count).contains(sector) else { return nil }
        return planetNames[sector - 1]
    }
}
