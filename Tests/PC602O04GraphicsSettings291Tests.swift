import Foundation

// O04 SOURCE-verified Renderer.cs option #2/#12/#13 and backward-compatible
// iOS settings from v568: no separate fake settings and no texture changes.
let suite="PC602O04GraphicsSettings291Tests"
guard let db=UserDefaults(suiteName:suite) else {
    fatalError("Unable to open isolated PC602 O04 test settings")
}
db.removePersistentDomain(forName:suite)
defer {db.removePersistentDomain(forName:suite)}
let defaultValues=SourcePlanetGraphicsSettings568.load(db)
assert(defaultValues.glowEnabled)
assert(defaultValues.nebulaEnabled)
assert(defaultValues.solarRaysEnabled)
assert(defaultValues.planetLightEnabled)
assert(defaultValues.planetLightSpeed==100)
assert(defaultValues.planetNightBrightness==160)

let legacy=Data("""
{"glowEnabled":false,"planetLightEnabled":false,
 "planetLightSpeed":175,"planetNightBrightness":220}
""".utf8)
db.set(legacy,forKey:SourcePlanetGraphicsSettings568.key)
let oldProfile=SourcePlanetGraphicsSettings568.load(db)
assert(!oldProfile.glowEnabled)
assert(!oldProfile.planetLightEnabled)
assert(oldProfile.planetLightSpeed==175)
assert(oldProfile.planetNightBrightness==220)
assert(oldProfile.nebulaEnabled)
assert(oldProfile.solarRaysEnabled)

let rev0=db.integer(forKey:SourcePlanetGraphicsSettings568.revisionKey)
var profile=oldProfile
profile.nebulaEnabled=false
profile.solarRaysEnabled=false
profile.save(db)
let rev1=db.integer(forKey:SourcePlanetGraphicsSettings568.revisionKey)
assert(rev1==rev0+1)
let disabled=SourcePlanetGraphicsSettings568.load(db)
assert(!disabled.glowEnabled && !disabled.nebulaEnabled
       && !disabled.solarRaysEnabled)
assert(!disabled.planetLightEnabled)
assert(disabled.planetLightSpeed==175)
assert(disabled.planetNightBrightness==220)
let encoded=db.data(forKey:SourcePlanetGraphicsSettings568.key)!
assert(String(data:encoded,encoding:.utf8)!.contains("solarRaysEnabled"))
assert(String(data:encoded,encoding:.utf8)!.contains("nebulaEnabled"))

profile=disabled
profile.glowEnabled=true
profile.nebulaEnabled=true
profile.solarRaysEnabled=true
profile.save(db)
assert(db.integer(forKey:SourcePlanetGraphicsSettings568.revisionKey)==rev1+1)
let enabled=SourcePlanetGraphicsSettings568.load(db)
assert(enabled.glowEnabled && enabled.nebulaEnabled
       && enabled.solarRaysEnabled)
assert(!enabled.planetLightEnabled)
assert(enabled.planetLightSpeed==175)
assert(enabled.planetNightBrightness==220)
print("PASS O04: PC602 glow/nebula/rays defaults, legacy settings migration, "
    + "on/off persistence, source graphics revision and planet profile isolation")
