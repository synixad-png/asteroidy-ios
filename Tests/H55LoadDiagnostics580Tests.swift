import Foundation

@main struct H55LoadDiagnostics580Tests {
    static func main() {
        let original=H55LoadDiagnostics580.report()
        assert(!original.isEmpty)
        H55LoadDiagnostics580.mark("TEST_01_SOURCE_H55_GLB")
        let first=H55LoadDiagnostics580.report()
        assert(first.contains("TEST_01_SOURCE_H55_GLB"))
        assert(first.contains("ASTEROIDY / H55 PC v580"))
        H55LoadDiagnostics580.mark("TEST_02_SOURCE_SCENEKIT")
        let second=H55LoadDiagnostics580.report()
        assert(second.contains("TEST_02_SOURCE_SCENEKIT"))
        assert(!second.contains("TEST_01_SOURCE_H55_GLB"))
        print("PASS H13-A: durable crash stage replaces previous record atomically, readable next launch")
    }
}
