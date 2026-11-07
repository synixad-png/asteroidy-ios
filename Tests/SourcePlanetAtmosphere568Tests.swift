import Foundation
@main struct SourcePlanetAtmosphere568Tests {
 static func main() {
  func check(_ cond:Bool,_ msg:String){if !cond{fatalError(msg)}}
  let a=SourcePlanetAtmosphere568.atmosphere(tint:SourcePlanetAtmosphere568.carbonisTint)
  let g=SourcePlanetAtmosphere568.glow(tint:SourcePlanetAtmosphere568.carbonisTint)
  check(a.count==24*96*6*7,"source atmosphere triangle count")
  check(g.count==12*96*6*6,"source glow triangle count")
  check(abs(a[2]-1.34)<0.00001,"source atmosphere front depth")
  check(abs(a[6]-0.058)<0.00001,"source center alpha")
  check(abs(SourcePlanetAtmosphere568.haze(1.34))<0.00001,"transparent outer edge")
  check(SourcePlanetAtmosphere568.haze(1.055)>0.30,"limb opacity")
  check(abs(g[0] - 0.94)<0.00001,"source halo start radius")
  check(g[2]>0 && g[3]>0 && g[4]>0,"premult additive color")
  let defaults=UserDefaults(suiteName:"com.synixad.asteroidyios.planetfx-test")!
  defaults.removePersistentDomain(forName:"com.synixad.asteroidyios.planetfx-test")
  var settings=SourcePlanetGraphicsSettings568()
  check(settings.planetLightSpeed==100 && settings.planetNightBrightness==160,"source defaults")
  settings.glowEnabled=false;settings.planetLightSpeed=413;settings.planetNightBrightness = -8
  settings.save(defaults)
  let stored=SourcePlanetGraphicsSettings568.load(defaults)
  check(!stored.glowEnabled && stored.planetLightSpeed==400 && stored.planetNightBrightness==0,"persist clamp")
  let sun=stored.sourceSun(0)
  check(abs(sun.0-cos(2.3)*0.9)<0.00001 && sun.3==0,"original sun")
  print("PASS SourcePlanetAtmosphere568 rings/haze/additive glow/settings/sun")
 }
}
