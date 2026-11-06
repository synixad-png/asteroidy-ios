import Foundation

/// Windows/src/MusicAudio.cs MusicMix.Render original v52/v55
/// 44,100 Hz combustion roar, filtered noise, compressor, stereo spread
/// and flame: exact source coefficients, seeds and update order.
/// Pure Swift for deterministic Linux and Apple engine-output tests.
struct OriginalEngineDSP52 {
    private static let tau:Double = 6.283185307179586
    private var enginePhase:Double = 0
    private var flamePhase:Double = 0
    private var engineSeed:UInt32 = 876123
    private var flameSeed:UInt32 = 58392
    private var engineAir:Float = 0
    private var engineLow:Float = 0
    private var engineMid:Float = 0
    private var engineTurbulence:Float = 0
    private var engineStereo:Float = 0
    private var engineTurbine:Double = 0
    private var engineGain:Float = 0
    private var flameGain:Float = 0
    private var flameNoise:Float = 0
    private var limiter:Float = 1
    private var fxGain:Float = -1

    mutating func render(engine target:Float,flame flameTarget:Float,
                         effectsVolume:Float)->(Float,Float) {
        let volume = max(0,min(1,effectsVolume))
        if fxGain<0 {fxGain=volume}
        fxGain += (volume-fxGain)*0.004
        engineGain += (max(0,min(1,target))-engineGain)*0.00012
        engineSeed = engineSeed &* 1664525 &+ 1013904223
        let air=Float(engineSeed >> 8)/8388608-1
        engineAir += (air-engineAir)*(0.19+engineGain*0.12)
        engineMid += (air-engineMid)*0.055
        engineLow += (air-engineLow)*0.012
        engineTurbulence += (air-engineTurbulence)*0.00018
        engineSeed = engineSeed &* 1664525 &+ 1013904223
        let stereo=Float(engineSeed >> 8)/8388608-1
        engineStereo += (stereo-engineStereo)*0.18
        enginePhase += Self.tau*Double(31+engineGain*26)/44100
        engineTurbine += Self.tau*Double(1150+engineGain*1550)/44100
        if enginePhase>Self.tau {enginePhase-=Self.tau}
        if engineTurbine>Self.tau {engineTurbine-=Self.tau}
        let roar = (engineLow*3.8 + (engineMid-engineLow)*1.8
                    + (engineAir-engineMid)*0.40)
        let compressor=Float(sin(engineTurbine)+0.25*sin(engineTurbine*2))*0.024
        let rawMotor = roar*(1+engineTurbulence*1.6)
                      + Float(sin(enginePhase))*0.035 + compressor
        let motor = rawMotor*engineGain*0.34*fxGain
        let spread=engineStereo*engineGain*0.022*fxGain
        var left=motor+spread
        var right=motor-spread
        flameGain += (max(0,min(1,flameTarget))-flameGain)*0.001
        flameSeed = flameSeed &* 1664525 &+ 1013904223
        let noise=Float(flameSeed >> 8)/8388608-1
        flameNoise += (noise-flameNoise)*0.13
        flamePhase += Self.tau*83/44100
        if flamePhase>Self.tau {flamePhase-=Self.tau}
        let torch=(flameNoise*0.85+Float(sin(flamePhase))*0.12)*flameGain*0.20*fxGain
        left+=torch;right+=torch
        let peak=max(abs(left),abs(right))
        let gain=peak>0.94 ? 0.94/peak : Float(1)
        limiter=gain<limiter ? gain : limiter+(gain-limiter)*0.00045
        left *= limiter;right *= limiter
        return (max(-0.99,min(0.99,left)),max(-0.99,min(0.99,right)))
    }
}
