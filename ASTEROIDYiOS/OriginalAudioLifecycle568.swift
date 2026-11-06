import Foundation

/// Byte fingerprints from the original Windows/SteamOS v568 source archive
/// build inventory, NOT inferred audio formats or waveform content.
/// These files are NOT present in the four partial GitHub resource ZIPs.
enum OriginalAudioManifest568 {
    static let introPCM="Shared/music/intro43.pcm.gz"
    static let introPCMSHA256="372d78e964c2d43b6c476488226d403547af4f2cfaafb650bc11fdedd9dc8b25"
    static let synthLicenses="Shared/music/SYNTH_LICENSES.txt"
    static let synthLicensesSHA256="8d790c6967996cb4903651087a73e961d846106c7ed3a6f4f2a01dfcc20eabfa615"
}

/// A source-verified PCM carrier only. Never generate replacement audio.
struct OriginalPCM568 {
    let sourceId:String
    let sampleRate:Double
    let channels:Int
    let interleavedFloat32:[Float]
    let loops:Bool
    var isValid:Bool {
        sampleRate.isFinite && sampleRate>0 &&
        (channels==1 || channels==2) &&
        !interleavedFloat32.isEmpty &&
        interleavedFloat32.count%channels==0 &&
        interleavedFloat32.allSatisfy{$0.isFinite && abs($0)<=1}
    }
}
struct OriginalMissionAudio568 {
    let music:OriginalPCM568?
    let effectsBySourceId:[String:OriginalPCM568]
    var isValid:Bool {
        (music==nil || music!.isValid) &&
        effectsBySourceId.allSatisfy{$0.key==$0.value.sourceId && $0.value.isValid}
    }
}
protocol OriginalAudioGenerator568 {
    func generateOriginalMenuMusic() throws -> OriginalPCM568
    func generateOriginalMissionAudio(sector:Int) throws -> OriginalMissionAudio568
}
enum OriginalAudioSourceError568:Error,CustomStringConvertible {
    case originalGeneratorNotAvailable
    case invalidOriginalAudio(String)
    var description:String {
        switch self {
        case .originalGeneratorNotAvailable:
            return "Brak źródłowego syntezatora v568 i intro43.pcm.gz; brak zastępczej melodii"
        case .invalidOriginalAudio(let id):
            return "Nieprawidłowy wynik oryginalnego generatora audio: \(id)"
        }
    }
}
/// Missing ORIGINAL files must never silently fall back to artificial music.
struct MissingOriginalAudioGenerator568:OriginalAudioGenerator568 {
    func generateOriginalMenuMusic() throws -> OriginalPCM568 {
        throw OriginalAudioSourceError568.originalGeneratorNotAvailable
    }
    func generateOriginalMissionAudio(sector:Int) throws -> OriginalMissionAudio568 {
        throw OriginalAudioSourceError568.originalGeneratorNotAvailable
    }
}
/// Phase 1: generate once at app launch; phase 2: generate bank lazily on
/// entering a source mission. All source generation uses ONE serial queue.
/// Returning to menu uses the cached source PCM. Generation never changes
/// physics timing, hitboxes or graphical state.
final class OriginalAudioLifecycle568 {
    enum Destination:Equatable {case menu,mission(Int)}
    enum Event {
        case menuReady(OriginalPCM568)
        case missionReady(Int,OriginalMissionAudio568)
        case unavailable(String)
    }
    private let generator:OriginalAudioGenerator568
    private let worker=DispatchQueue(label:"synixad.asteroidy.audio568.source",
                                     qos:.userInitiated)
    private let lock=NSLock()
    private var destination:Destination = .menu
    private var revision:UInt64=0
    private var menuAttempted=false
    private var menu:OriginalPCM568?
    private var menuFailure:String?
    private var missions:[Int:OriginalMissionAudio568]=[:]
    private var missionFailures:[Int:String]=[:]
    var onEvent:((Event)->Void)?
    init(generator:OriginalAudioGenerator568=MissingOriginalAudioGenerator568()) {
        self.generator=generator
    }
    func prepareAtStartup() {openMenu()}
    func openMenu() {
        let request=setDestination(.menu)
        worker.async { [self] in
            prepareMenuOnce()
            if let menu {
                deliver(.menu,request:request,event:.menuReady(menu))
            } else {
                deliver(.menu,request:request,
                        event:.unavailable(menuFailure ?? "Brak oryginalnego audio menu"))
            }
        }
    }
    func openMission(sector:Int) {
        guard (1...26).contains(sector) else {return}
        let requested=Destination.mission(sector)
        let request=setDestination(requested)
        worker.async { [self] in
            prepareMenuOnce() // menu always first, even for a fast mission entry
            if let bank=missions[sector] {
                deliver(requested,request:request,event:.missionReady(sector,bank))
                return
            }
            if let failed=missionFailures[sector] {
                deliver(requested,request:request,event:.unavailable(failed))
                return
            }
            do {
                let result=try generator.generateOriginalMissionAudio(sector:sector)
                guard result.isValid else {
                    throw OriginalAudioSourceError568.invalidOriginalAudio("mission \(sector)")
                }
                missions[sector]=result
                deliver(requested,request:request,event:.missionReady(sector,result))
            } catch {
                missionFailures[sector]=String(describing:error)
                deliver(requested,request:request,
                        event:.unavailable(String(describing:error)))
            }
        }
    }
    private func prepareMenuOnce() {
        guard !menuAttempted else {return}
        menuAttempted=true
        do {
            let result=try generator.generateOriginalMenuMusic()
            guard result.isValid else {
                throw OriginalAudioSourceError568.invalidOriginalAudio("menu")
            }
            menu=result
        } catch {
            menuFailure=String(describing:error)
        }
    }
    @discardableResult
    private func setDestination(_ requested:Destination)->UInt64 {
        lock.lock();defer{lock.unlock()}
        revision &+= 1;destination=requested;return revision
    }
    private func deliver(_ expected:Destination,request:UInt64,event:Event) {
        DispatchQueue.main.async { [self] in
            lock.lock()
            let valid=destination==expected && revision==request
            lock.unlock()
            if valid {onEvent?(event)}
        }
    }
}
