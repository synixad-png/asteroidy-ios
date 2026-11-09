import Foundation

/// H55 load breadcrumb written before and after potentially expensive work.
/// Stored separately from original GLB and outside the per-frame renderer.
/// If iOS kills the app during GLTF/SceneKit initialization, the last stage
/// remains readable from Settings > HANGAR after relaunch.
enum H55LoadDiagnostics580 {
    private static let mutex = NSLock()
    private static let name = "H55_LOAD_STAGE_580.txt"

    private static func fileURL() -> URL? {
        guard let folder=FileManager.default.urls(
            for:.applicationSupportDirectory,in:.userDomainMask).first else {return nil}
        try? FileManager.default.createDirectory(
            at:folder,withIntermediateDirectories:true)
        return folder.appendingPathComponent(name,isDirectory:false)
    }

    static func mark(_ stage:String) {
        mutex.lock()
        defer {mutex.unlock()}
        guard let file=fileURL() else{return}
        let timestamp=ISO8601DateFormatter().string(from:Date())
        let payload="ASTEROIDY / H55 PC v580\n" +
                    "OSTATNI ZAREJESTROWANY ETAP: \(stage)\n" +
                    "CZAS: \(timestamp)\n" +
                    "Zapis wskazuje etap wykonywany lub ostatnio ukończony, " +
                    "nie stanowi samodzielnego dowodu przyczyny awarii.\n"
        try? Data(payload.utf8).write(to:file,options:.atomic)
    }

    static func report() -> String {
        mutex.lock()
        defer {mutex.unlock()}
        guard let file=fileURL(),
              let text=try? String(contentsOf:file,encoding:.utf8) else {
            return "H55 PC v580: nie zapisano jeszcze próby ładowania."
        }
        return text
    }
}
