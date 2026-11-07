import Foundation

// Native iOS/Swift port of the actual v568 Windows/src music generator:
// MusicSynth.cs, SynthDsp.cs, SynthCoefficients.cs, SynthRandom.cs,
// MusicMaster.cs. Not a substituted tune or pre-recorded AAC playback.
// The 15 pieces are generated to temporary 44.1-kHz stereo PCM WAV at
// application startup, just as the original MusicBank.Generate creates PCM.
// Original 6,144-byte zig.bin is a NumPy BSD-3-Clause lookup table.

private struct SourceRng568 {
    private var hi: UInt64, lo: UInt64, ih: UInt64, il: UInt64
    private let fi: [Double], wi: [Double], ki: [UInt64]
    private static let seeds: [[UInt64]] = [
        [17720626838516207804,17604308112068095111,13442669393644191452,16392051441657752093],
        [1516675780555050764,11817444579787549802,4171121331024154263,4370545984452587435],
        [7317589267772807375,8817657662573731448,807272480506421524,6163486463551129069],
        [14307938573285740446,9056080682619171725,9201328663824832966,14206366224349684113],
        [7364247954233186185,9407711808168926477,2271866509686706354,17793606685775104749]
    ]
    private static let embeddedZigBase64 = "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"
    init(track: Int, zigURL: URL? = nil) throws {
        let data: Data
        if let zigURL {data = try Data(contentsOf: zigURL)}
        else {guard let decoded=Data(base64Encoded:Self.embeddedZigBase64) else {throw SynthError568.invalidZigTable};data=decoded}
        guard data.count == 6144 else { throw SynthError568.invalidZigTable }
        var values = [UInt64](repeating: 0, count: 768)
        data.withUnsafeBytes { bytes in
            for i in 0..<768 {
                var word: UInt64 = 0
                memcpy(&word, bytes.baseAddress!.advanced(by: i*8), 8)
                values[i] = UInt64(littleEndian: word)
            }
        }
        fi = values[0..<256].map { Double(bitPattern: $0) }
        wi = values[256..<512].map { Double(bitPattern: $0) }
        ki = Array(values[512..<768])
        let seed = Self.seeds[track % 5]
        hi=seed[0]; lo=seed[1]; ih=seed[2]; il=seed[3]
        if track >= 5 { for _ in 0..<(track*113) { _=next() } }
    }
    @inline(__always) private mutating func next() -> UInt64 {
        let ml: UInt64=4865540595714422341, mh: UInt64=2549297995355413924
        let nh = lo.multipliedFullWidth(by:ml).high &+ (hi &* ml) &+ (lo &* mh)
        let nl = lo &* ml
        let sum = nl &+ il
        hi = nh &+ ih &+ (sum < nl ? 1 : 0)
        lo = sum
        let x=hi^lo, rot=Int(hi>>58)
        return (x>>rot)|(x<<((-rot)&63))
    }
    mutating func uniform() -> Double {
        Double(next()>>11)*(1.0/9007199254740992.0)
    }
    mutating func normal() -> Double {
        while true {
            var r=next()
            let idx=Int(r & 255)
            r >>= 8
            let absolute=(r>>1)&0x000f_ffff_ffff_ffff
            var x=Double(absolute)*wi[idx]
            if (r&1) != 0 { x = -x }
            if absolute < ki[idx] { return x }
            if idx == 0 {
                while true {
                    let xx = -log(1-uniform())/3.6541528853610088
                    let yy = -log(1-uniform())
                    if yy+yy > xx*xx {
                        return ((absolute>>8)&1) != 0 ? -(3.6541528853610088+xx) : (3.6541528853610088+xx)
                    }
                }
            } else if (fi[idx-1]-fi[idx])*uniform()+fi[idx] < exp(-0.5*x*x) {
                return x
            }
        }
    }
}

enum SynthError568: Error { case invalidZigTable, invalidTrack, invalidPCM, cancelled }

private struct SourceBus568 {
    var left:[Float]
    var right:[Float]
    init(_ n:Int){left=[Float](repeating:0,count:n);right=[Float](repeating:0,count:n)}
}

private enum SourceDsp568 {
    static let rate=44100,tau=6.283185307179586
    static let fir: [Double] = [-7.158970950886459e-19,-0.0010514587726751215,1.8542998243319006e-18,0.0025089668121477146,-3.494145233950968e-18,-0.004894834339287572,5.60645116237481e-18,0.008556559002481406,-8.091013094452995e-18,-0.01398997323843515,1.0781132014374604e-17,0.022023120574074614,-1.3459677422897392e-17,-0.03434017988174492,1.5884600682954174e-17,0.05528828391185702,-1.78202070879486e-17,-0.10093019739773386,1.9069296838463637e-17,0.31670034568030075,0.5002587352980301,0.31670034568030075,1.9069296838463637e-17,-0.10093019739773386,-1.78202070879486e-17,0.05528828391185702,1.5884600682954174e-17,-0.03434017988174492,-1.3459677422897392e-17,0.022023120574074614,1.0781132014374604e-17,-0.01398997323843515,-8.091013094452995e-18,0.008556559002481406,5.60645116237481e-18,-0.004894834339287572,-3.494145233950968e-18,0.0025089668121477146,1.8542998243319006e-18,-0.0010514587726751215,-7.158970950886459e-19]
    static let filters: [String:[Double]] = [
        "lowpass:9000": [0.21320719693771073,0.42641439387542146,0.21320719693771073,1.0,-0.3391511849431443,0.1919799726939872],
        "highpass:29": [0.9970826400792283,-1.9941652801584566,0.9970826400792283,1.0,-1.9941567691514406,0.9941737911654738],
        "lowpass:7000": [0.1434934668551738,0.2869869337103476,0.1434934668551738,1.0,-0.6807407016876916,0.25471456910838697],
        "highpass:6500": [0.5114320423301106,-1.0228640846602213,0.5114320423301106,1.0,-0.7679157752851989,0.27781239403524355],
        "highpass:2500": [0.7770237852040119,-1.5540475704080239,0.7770237852040119,1.0,-1.5036953412992213,0.6043997995168271],
        "highpass:900": [0.9133108730258188,-1.8266217460516376,0.9133108730258188,1.0,-1.8190925691900384,0.8341509229132364],
        "lowpass:7500": [0.16008914307886488,0.32017828615772975,0.16008914307886488,1.0,-0.5943729542483326,0.23472952656379206],
        "highpass:1800": [0.8340512655924619,-1.6681025311849238,0.8340512655924619,1.0,-1.6403712933454329,0.6958337690244153],
        "lowpass:6200": [0.11814885074930818,0.23629770149861637,0.11814885074930818,1.0,-0.8206465195249032,0.293241922522136],
        "highpass:25": [0.9974845279889571,-1.9949690559779143,0.9974845279889571,1.0,-1.9949627283684663,0.9949753835873623],
        "lowpass:1200": [0.00650713740104626,0.01301427480209252,0.00650713740104626,1.0,-1.7591969461508574,0.7852254957550425],
        "lowpass:1450": [0.00928519686013298,0.01857039372026596,0.00928519686013298,1.0,-1.7095165404698356,0.7466573279103675],
        "lowpass:1700": [0.01247842050532761,0.02495684101065522,0.01247842050532761,1.0,-1.6600756683980304,0.7099893504193409],
        "lowpass:1950": [0.016058879947024585,0.03211775989404917,0.016058879947024585,1.0,-1.6108955609769042,0.6751310807650026],
        "lowpass:2200": [0.020000998510055188,0.040001997020110376,0.020000998510055188,1.0,-1.561993193568188,0.641997187608409],
        "acid:650": [0.0013353350125606708,0.0026706700251213416,0.0013353350125606708,1.0,-1.919484179443767,0.9334243251703007,1.0,-2.0,1.0,1.0,-1.9593764989397187,0.9634933481801725],
        "acid:860": [0.0022994455227373493,0.004598891045474699,0.0022994455227373493,1.0,-1.8887774184870396,0.9129056835102219,1.0,-2.0,1.0,1.0,-1.9447937887295603,0.951956647574485],
        "acid:1070": [0.0035021999036989482,0.0070043998073978965,0.0035021999036989482,1.0,-1.8559326791260196,0.8928616071998328,1.0,-2.0,1.0,1.0,-1.9295133970503344,0.9405337019935347],
        "acid:1280": [0.004932017867130229,0.009864035734260458,0.004932017867130229,1.0,-1.8210383972261153,0.8732865951420798,1.0,-2.0,1.0,1.0,-1.9135442244588021,0.929217745988406],
        "acid:1490": [0.006577977865321372,0.013155955730642745,0.006577977865321372,1.0,-1.7841813855516935,0.8541751350317888,1.0,-2.0,1.0,1.0,-1.8968954291059734,0.9180022339601969],
        "acid:1700": [0.008429782269430681,0.016859564538861362,0.008429782269430681,1.0,-1.7454468457354322,0.8355217477453247,1.0,-2.0,1.0,1.0,-1.8795764296603579,0.9068808235311197],
        "acid:1910": [0.010477724217843248,0.020955448435686495,0.010477724217843248,1.0,-1.7049183841648,0.8173210280346139,1.0,-2.0,1.0,1.0,-1.861596908445827,0.8958473598623932],
        "acid:2120": [0.01271265609672976,0.02542531219345952,0.01271265609672976,1.0,-1.66267803093573,0.7995676820112604,1.0,-2.0,1.0,1.0,-1.8429668148304015,0.8848958608348719],
        "acid:2330": [0.015125959608239424,0.030251919216478847,0.015125959608239424,1.0,-1.6188062611245488,0.7822565618751975,1.0,-2.0,1.0,1.0,-1.823696368906894,0.8740205030156152],
        "acid:2540": [0.01770951737673852,0.03541903475347704,0.01770951737673852,1.0,-1.573382017717818,0.7653826983150236,1.0,-2.0,1.0,1.0,-1.803796065511466,0.8632156083402197],
        "acid:2750": [0.020455686039867506,0.04091137207973501,0.020455686039867506,1.0,-1.526482735617017,0.7489413309838112,1.0,-2.0,1.0,1.0,-1.7832766786318317,0.8524756314467693],
    ]
    static func filtered(_ input:[Float],_ key:String,
                         checkpoint:()->Void={}) -> [Float] {
        guard let sos=filters[key] else {preconditionFailure("Missing original source SOS filter: \(key)")}
        var out=[Float](repeating:0,count:input.count)
        var z=[Double](repeating:0,count:sos.count/3)
        for i in input.indices {
            // Two full-song mastering passes operate on millions of
            // samples. Yield on a deterministic block boundary while
            // combat is active; do not touch SOS coefficients or audio.
            if (i & 16383)==0 {checkpoint()}
            var v=Double(input[i])
            for j in stride(from:0,to:sos.count,by:6) {
                let q=j/3
                let y=sos[j]*v+z[q]
                z[q]=sos[j+1]*v-sos[j+4]*y+z[q+1]
                z[q+1]=sos[j+2]*v-sos[j+5]*y
                v=y
            }
            out[i]=Float(v)
        }
        return out
    }
    static func filtered(_ input:[Double],_ key:String) -> [Float] {
        guard let sos=filters[key] else {preconditionFailure("Missing original source SOS filter: \(key)")}
        var out=[Float](repeating:0,count:input.count)
        var z=[Double](repeating:0,count:sos.count/3)
        for i in input.indices {
            var v=input[i]
            for j in stride(from:0,to:sos.count,by:6) {
                let q=j/3
                let y=sos[j]*v+z[q]
                z[q]=sos[j+1]*v-sos[j+4]*y+z[q+1]
                z[q+1]=sos[j+2]*v-sos[j+5]*y
                v=y
            }
            out[i]=Float(v)
        }
        return out
    }
    @inline(__always) static func frequency(_ n:Int)->Double{440*pow(2,Double(n-69)/12)}
    @inline(__always) static func envelope(_ i:Int,_ n:Int,_ attack:Double,_ decay:Double)->Double {
        var e=min(1,Double(i)/(Double(rate)*max(0.0001,attack)))*exp(-Double(i)/(Double(rate)*max(0.01,decay)))
        let edge=min(n,220)
        if i>=n-edge {e *= Double(n-1-i)/Double(edge-1)}
        return e
    }
    static func kick()->[Float] {
        let n=Int(0.34*Double(rate))
        var x=[Double](repeating:0,count:n),phase=0.0
        for i in 0..<n {
            let t=Double(i)/Double(rate)
            phase += tau*(46+150*exp(-t/0.018)+35*exp(-t/0.075))/Double(rate)
            let body=sin(phase)*envelope(i,n,0.0012,0.11)
            x[i]=tanh(body*1.55)/1.2+sin(tau*3500*t)*exp(-t/0.0019)*0.12
        }
        return filtered(x,"lowpass:9000")
    }
    static func bass(_ note:Int,_ seconds:Double)->[Float] {
        let n=Int(seconds*Double(rate));var harmonic=[Float](repeating:0,count:n)
        let f=frequency(note)
        for h in 1...30 {
            let angle=tau*f*Double(h)/Double(rate),c=cos(angle),s=sin(angle)
            var re=cos(0.08),im=sin(0.08)
            for i in 0..<n {
                let t=Double(i)/Double(rate),cut=230+1800*exp(-t/0.012),ratio=Double(h)*f/cut
                harmonic[i] += Float(im/(Double(h)*sqrt(1+pow(ratio,4))))
                let nr=re*c-im*s
                im=im*c+re*s;re=nr
            }
        }
        var x=[Double](repeating:0,count:n)
        for i in 0..<n {
            x[i]=tanh((Double(harmonic[i])*0.58+0.36*sin(tau*f*Double(i)/Double(rate)))*1.35)*envelope(i,n,0.0035,0.14)
        }
        return filtered(x,"highpass:29")
    }
    static func downsample(_ high:[Double]) -> [Float] {
        let n=high.count
        var down=[Float](repeating:0,count:(n+1)/2)
        for i in down.indices {
            var sum=0.0
            for k in fir.indices {
                let at=i*2+k-20
                if at>=0 && at<n {sum+=high[at]*fir[k]}
            }
            down[i]=Float(sum)
        }
        return down
    }
    static func acid(_ note:Int,_ duration:Double,_ index:Int,_ variant:Int)->[Float]{
        let n=Int(duration*Double(rate)*2)
        var high=[Double](repeating:0,count:n)
        let f=frequency(note),idx=1.2+Double(variant)*0.24
        for i in 0..<n {
            let t=Double(i)/(Double(rate)*2),e=min(1,t/0.004)*exp(-t/0.11)
            high[i]=(sin(tau*f*t+idx*sin(tau*f*2*t)*exp(-t/0.075))*0.68 + sin(tau*f*1.003*t+0.45)*0.25)*e
        }
        var down=downsample(high)
        let hz=650+((index*17+variant*9)%11)*210
        let bp=filtered(down,"acid:\(hz)"),lp=filtered(down,"lowpass:7000")
        for i in down.indices {
            var value=Double(lp[i])+Double(bp[i])*0.8
            if i>=down.count-220 { value *= Double(down.count-1-i)/219 }
            down[i]=Float(tanh(value*1.5))
        }
        return down
    }
    static func lead(_ note:Int,_ duration:Double,_ index:Int,_ style:Int)->[Float] {
        let family=style,n=Int(duration*Double(rate)*2)
        var high=[Double](repeating:0,count:n)
        let f=frequency(note),tone=0.85+Double(style/6)*0.18 // Source C# integer division
        for i in 0..<n {
            let t=Double(i)/(Double(rate)*2)
            let env=min(1,t/0.004)*exp(-t/(family==6 ? 0.065 : (family==2 || family==7 ? 0.16 : 0.115)))
            let p=tau*f*t
            let value:Double
            switch family {
            case 0:value=sin(p+(2.5+Double(index)*0.04)*sin(p*2)*exp(-t/0.045))*0.65+sin(p*1.006)*0.2
            case 1:value=(sin(p*0.996)+sin(p*1.004+0.4)+sin(p*1.008+0.8))*0.25+sin(p*2)*0.15
            case 2:value=sin(p+2.1*sin(p*3)*exp(-t/0.09))*0.7+sin(p*2.001)*0.18
            case 3:value=sin(p+3*sin(p*0.5))*sin(tau*(650+Double(index)*35)*t)*0.55+sin(p)*0.25
            case 4:value=sin(p+2*sin(p*2+sin(tau*11*t)))*0.68+sin(p*2.004)*0.14
            case 5:value=sin(p+1.3*sin(p*3.01)*exp(-t/0.07))*0.6+sin(p*2)*0.24
            case 6:value=(sin(p)+sin(p*2)*0.32+sin(p*3)*0.12)*0.6
            case 7:value=sin(p+sin(p*2)*1.5)*0.45+sin(p*2.002+sin(p*4)*0.65)*0.35
            case 8:value=sin(p+2.6*sin(p*2)*exp(-t/0.12))*0.6+sin(p*1.002+0.7)*0.2
            default:value=(sin(p*0.997+sin(p*2)*0.9)+sin(p*1.003+0.8+sin(p*3)*0.8))*0.38
            }
            high[i]=value*env*tone
        }
        var down=downsample(high)
        let hz=650+((index*13+style*7)%11)*210
        let bp=filtered(down,"acid:\(hz)")
        let lp=filtered(down,"lowpass:7000")
        for i in down.indices {
            var value=Double(lp[i])+Double(bp[i])*(family==0 || family==4 ? 0.8 : 0.35)
            if i>=down.count-220 {value *= Double(down.count-1-i)/219}
            down[i]=Float(tanh(value*1.35))
        }
        return down
    }
    static func percussion(_ rng:inout SourceRng568,_ kind:String)->[Float] {
        let seconds=kind=="closed" ? 0.07 : kind=="open" ? 0.25 : kind=="clap" ? 0.19 : kind=="shaker" ? 0.095 : 0.2
        let n=Int(seconds*Double(rate))
        var noise=[Float](repeating:0,count:n)
        for i in noise.indices {noise[i]=Float(rng.normal())}
        if kind=="tom" {
            var phase=0.0
            for i in noise.indices {
                phase+=tau*(95+110*exp(-Double(i)/(Double(rate)*0.04)))/Double(rate)
                noise[i]=Float(sin(phase)*envelope(i,n,0.001,0.06)*0.7)
            }
            return noise
        }
        var result=[Float](repeating:0,count:n)
        if kind=="clap" {
            let wires=filtered(filtered(noise,"highpass:1800"),"lowpass:7500")
            var phase=0.0
            for i in noise.indices {
                let t=Double(i)/Double(rate)
                phase+=tau*(178+40*exp(-t/0.012))/Double(rate)
                let body=(sin(phase)*0.68+sin(tau*331*t)*0.18)*envelope(i,n,0.0015,0.042)
                let wire=Double(wires[i])*0.23*envelope(i,n,0.003,0.033)
                result[i]=Float(body+wire)
            }
            normalize(&result,0.64)
            return result
        }
        let hat=kind=="closed" || kind=="open"
        let air=filtered(filtered(noise,hat ? "highpass:6500" : "highpass:2500"),"lowpass:9000")
        let decay=kind=="closed" ? 0.017 : kind=="open" ? 0.052 : 0.024
        for i in noise.indices {
            let t=Double(i)/Double(rate)
            let metal=hat ? (sin(tau*3821*t)+sin(tau*5179*t+0.3)+sin(tau*6473*t+0.8)+sin(tau*8123*t+1.4)+sin(tau*10213*t+2.1))*0.09 : 0
            result[i]=Float((metal+Double(air[i])*(hat ? 0.10 : 0.22))*envelope(i,n,0.0012,decay))
        }
        normalize(&result,kind=="closed" ? 0.36 : kind=="open" ? 0.42 : 0.28)
        return result
    }
    static func normalize(_ voice:inout [Float],_ peak:Float){
        var maxSample:Float=0
        for sample in voice {maxSample=max(maxSample,abs(sample))}
        if maxSample>0 {let gain=peak/maxSample;for i in voice.indices {voice[i]*=gain}}
    }
    static func pad(_ key:Int,_ variant:Int,_ section:Int,_ duration:Double)->SourceBus568 {
        let n=Int(duration*Double(rate)),root=key+24+[0,0,3,0,7,0,3,0][section]
        var bus=SourceBus568(n)
        for note in [root,root+7,root+15] {
            for side in 0..<2 {
                let f=frequency(note)*(side==0 ? 0.9985 : 1.0015)
                var saw=[Float](repeating:0,count:n)
                let hs=min(64,Int(1800/f))
                if hs>=1 { for h in 1...hs {
                    let angle=tau*f*Double(h)/Double(rate),c=cos(angle),s=sin(angle)
                    var re=1.0,im=0.0
                    for i in 0..<n {
                        saw[i]+=Float(im/Double(h))
                        let nr=re*c-im*s
                        im=im*c+re*s;re=nr
                    }
                }}
                let mul:Float=Float(2/Double.pi)*0.06
                if side==0 {for i in 0..<n {bus.left[i]+=saw[i]*mul}}
                else {for i in 0..<n {bus.right[i]+=saw[i]*mul}}
            }
        }
        for side in 0..<2 {
            var channel=side==0 ? bus.left : bus.right
            for i in channel.indices {
                let t=Double(i)/Double(rate)
                channel[i]=Float(Double(channel[i])*pow(sin(Double.pi*min(1,t/duration)),1.4)*(0.5+0.12*sin(tau*0.13*t)))
            }
            channel=filtered(channel,"lowpass:\(1200+variant*250)")
            if side==0 {bus.left=channel} else {bus.right=channel}
        }
        return bus
    }
    static func noiseSwell(_ rng:inout SourceRng568,_ count:Int)->[Float] {
        var noise=[Float](repeating:0,count:count)
        for i in noise.indices {noise[i]=Float(rng.normal()*0.1)}
        var swell=filtered(noise,"highpass:1800")
        for i in swell.indices {
            var edge=min(1,Double(count-1-i)/(Double(rate)*0.012))
            edge=edge*edge*(3-2*edge)
            swell[i]=Float(Double(swell[i])*pow(Double(i)/Double(count-1),2)*edge)
        }
        return swell
    }
    static func add(_ bus:inout SourceBus568,_ voice:[Float],_ start:Double,_ gain:Double,_ pan:Double) {
        var at=Int((start*Double(rate)).rounded(.toNearestOrEven))
        let g=Float(gain),l=Float(sqrt((1-pan)/2)),r=Float(sqrt((1+pan)/2))
        for i in voice.indices {
            if at>=bus.left.count {break}
            let v=voice[i]*g
            bus.left[at]+=v*l;bus.right[at]+=v*r;at+=1
        }
    }
    static func add(_ bus:inout SourceBus568,_ voice:SourceBus568,_ start:Double,_ gain:Double) {
        var at=Int((start*Double(rate)).rounded(.toNearestOrEven))
        let g=Float(gain)
        for i in voice.left.indices {
            if at>=bus.left.count {break}
            bus.left[at]+=voice.left[i]*g;bus.right[at]+=voice.right[i]*g;at+=1
        }
    }
    @inline(__always) static func sidechain(_ frame:Int,_ beat:Double)->Double {
        let phase=(Double(frame)/Double(rate)).truncatingRemainder(dividingBy:beat)
        var down=min(1,(beat-phase)/0.004)
        down=down*down*(3-2*down)
        return 0.35+0.65*(1-exp(-phase/0.048))*down
    }
}

/// Exact 131,072-point packed-stereo FFT convolution from SynthDsp.cs.
/// Streams reverb directly to the main bus instead of allocating another
/// 2x ~40 MB float bus, which matters on older iPhone models.
private final class SourceReverb568 {
    private let n=131072,hop=65536
    private var twiddleCos:[Double],twiddleSin:[Double],reverse:[Int]
    init(){
        twiddleCos=[Double](repeating:0,count:65536)
        twiddleSin=[Double](repeating:0,count:65536)
        reverse=[Int](repeating:0,count:131072)
        for i in 0..<65536 {
            twiddleCos[i]=cos(SourceDsp568.tau*Double(i)/131072)
            twiddleSin[i]=sin(SourceDsp568.tau*Double(i)/131072)
        }
        var j=0
        for i in 1..<131072 {
            var bit=65536
            while (j & bit) != 0 {j ^= bit;bit >>= 1}
            j ^= bit
            reverse[i]=j
        }
    }
    private func fft(_ re:inout [Double],_ im:inout [Double],inverse:Bool){
        for i in 0..<n {
            let j=reverse[i]
            if j>i {
                re.swapAt(i,j);im.swapAt(i,j)
            }
        }
        var len=2
        while len<=n {
            let half=len>>1,step=n/len
            var at=0
            while at<n {
                var k=0
                for j in 0..<half {
                    let c=twiddleCos[k],s=(inverse ? twiddleSin[k] : -twiddleSin[k])
                    let a=at+j,b=a+half
                    let r=re[b]*c-im[b]*s,t=re[b]*s+im[b]*c
                    re[b]=re[a]-r;im[b]=im[a]-t
                    re[a]+=r;im[a]+=t
                    k+=step
                }
                at+=len
            }
            len<<=1
        }
        if inverse {
            for i in 0..<n {re[i]/=Double(n);im[i]/=Double(n)}
        }
    }
    private func multiply(_ re:inout [Double],_ im:inout [Double],
                          _ k:Int,_ ar:Double,_ ai:Double,_ br:Double,_ bi:Double,
                          _ lr:[Double],_ li:[Double],_ rr:[Double],_ ri:[Double]){
        let lre=(ar+br)*0.5,lim=(ai-bi)*0.5,rre=(ai+bi)*0.5,rim=(br-ar)*0.5
        let leftR=lre*lr[k]-lim*li[k],leftI=lre*li[k]+lim*lr[k]
        let rightR=rre*rr[k]-rim*ri[k],rightI=rre*ri[k]+rim*rr[k]
        re[k]=leftR-rightI;im[k]=leftI+rightR
    }
    func render(_ source:SourceBus568, impulse:SourceBus568,
                main:inout SourceBus568,space:SourceBus568,
                progress:(String)->Void,
                checkpoint:()->Void={}) {
        let frames=source.left.count,irLen=impulse.left.count
        var hr=[Double](repeating:0,count:n),hi=[Double](repeating:0,count:n)
        for i in 0..<irLen {hr[i]=Double(impulse.left[i]);hi[i]=Double(impulse.right[i])}
        fft(&hr,&hi,inverse:false)
        var lr=[Double](repeating:0,count:n),li=lr,rr=lr,ri=lr
        for k in 0..<n {
            let neg=(n-k)%n
            lr[k]=(hr[k]+hr[neg])*0.5
            li[k]=(hi[k]-hi[neg])*0.5
            rr[k]=(hi[k]+hi[neg])*0.5
            ri[k]=(hr[neg]-hr[k])*0.5
        }
        var re=[Double](repeating:0,count:n),im=re
        var carryL=[Float](repeating:0,count:irLen-1),carryR=carryL
        var at=0
        while at<frames {
            // FFT convolution has the largest contiguous CPU bursts.
            // The source overlap/add result is unchanged across a wait.
            checkpoint()
            if (at/hop)%8==0 {progress("Pogłos stereo — \(at*100/frames)%")}
            for i in 0..<n {re[i]=0;im[i]=0}
            let count=min(hop,frames-at)
            for i in 0..<count {re[i]=Double(source.left[at+i]);im[i]=Double(source.right[at+i])}
            fft(&re,&im,inverse:false)
            // Packed-stereo FFT; source uses k and -k pairs exactly this way.
            for k in 0...(n/2) {
                let neg=(n-k)%n
                let ar=re[k],ai=im[k],br=re[neg],bi=im[neg]
                multiply(&re,&im,k,ar,ai,br,bi,lr,li,rr,ri)
                if neg != k {multiply(&re,&im,neg,br,bi,ar,ai,lr,li,rr,ri)}
            }
            fft(&re,&im,inverse:true)
            for i in 0..<count {
                let wetL=Float(re[i])+(i<carryL.count ? carryL[i] : 0)
                let wetR=Float(im[i])+(i<carryR.count ? carryR[i] : 0)
                main.left[at+i] += space.left[at+i]+wetL*0.6
                main.right[at+i] += space.right[at+i]+wetR*0.6
            }
            if at+count<frames {
                // The impulse is shorter than the 65,536-frame hop;
                // only the immediately preceding block overlaps.
                for i in carryL.indices {
                    let pos=count+i
                    carryL[i]=Float(re[pos])
                    carryR[i]=Float(im[pos])
                }
            }
            at+=hop
        }
    }
}

enum OriginalMusicSynth568 {
    static let count=15,bars=128,rate=44100
    static let names=["Astral Gate","Orbital Pulse","Crystal Hive","Nyx Protocol","Event Horizon","Solar Serpent","Prismatic Drive","Quantum Lotus","Alien Resonance","Neon Shaman","Helix Reactor","Plasma Garden","Fractal Voyager","Moon Circuit","Stellar Bloom"]
    static let bpm=[128,140,144,146,148,140,140,140,140,140,140,140,140,140,140]
    private static let keys=[29,31,29,26,28,31,29,33,26,28,31,29,26,33,28]
    private static let patterns:[[Int]]=[
        [0,0,7,0,0,3,0,10],[0,3,0,7,0,10,7,3],[0,0,3,0,7,0,5,10],
        [0,7,0,3,0,10,0,5],[0,3,7,10,7,3,0,5],[0,3,7,3,10,7,5,3],
        [0,7,12,10,7,3,5,7],[0,5,7,12,10,7,5,3],[0,1,7,3,10,8,7,3],
        [0,3,5,7,10,7,3,0],[0,7,0,12,3,10,7,5],[0,3,7,10,12,10,7,3],
        [0,12,7,15,10,7,5,3],[0,3,0,5,7,10,8,7],[0,7,10,12,15,12,10,7]]
    private static let sections=[0,1,2,3,4,5,6,7,4,1,5,6,3,5,6,7]
    private static let strengths:[Double]=[0.65,0.82,1,1,0.22,0.95,1,0.78]
    static func frames(_ track:Int,_ countBars:Int=128)->Int {
        Int((Double(countBars)*4*60/Double(bpm[track])*Double(rate)).rounded(.toNearestOrEven))
    }
    static func generate(track:Int, zigURL:URL? = nil, destination:URL,
                         testBars:Int=128,checkpoint:()->Void={},
                         progress:(String)->Void={_ in}) throws -> URL {
        guard (0..<count).contains(track), testBars>0, testBars<=bars else {throw SynthError568.invalidTrack}
        let v=track,r=Double(rate),key=keys[v],voice=v<5 ? v : 1,driving=v != 0
        let beat=60/Double(bpm[v]),bar=beat*4
        let frames=Int((Double(testBars)*bar*r).rounded(.toNearestOrEven))
        checkpoint()
        var rng=try SourceRng568(track:v,zigURL:zigURL)
        var main=SourceBus568(frames),space=SourceBus568(frames),delay=SourceBus568(frames)
        let kick=SourceDsp568.kick()
        var perc:[String:[Float]]=[:]
        for kind in ["closed","open","clap","shaker","tom"] {perc[kind]=SourceDsp568.percussion(&rng,kind)}
        var bass:[Int:[Float]]=[:],acid:[Int:[Float]]=[:],pads:[Int:SourceBus568]=[:]
        progress("Synteza barw i aranżacji")
        for b in 0..<testBars {
            // The source 8-bar progress callback may run seconds apart.
            // One checkpoint per bar makes pausing prompt and lossless.
            checkpoint()
            if b%8==0 {progress("Synteza aranżacji — takt \(b+1) / \(testBars)")}
            let section=sections[b/8],breakdown=sections[b/8]==4
            let strength=strengths[section]*(driving ? 1 : 0.65)
            for q in 0..<4 {
                let at=Double(b*4+q)*beat
                if b>=4 && b<126 && (!breakdown || q==0){SourceDsp568.add(&main,kick,at,0.83*strength,0)}
                for s in [1,2,3] {
                    let note=key + (v==4 && s==3 && b%4==3 ? 12 : 0) + ((b%16==14 || b%16==15) && s==3 ? 3 : 0)
                    if bass[note]==nil {bass[note]=SourceDsp568.bass(note,beat/4*0.88)}
                    if !breakdown && b>=4 && b<126 {
                        SourceDsp568.add(&main,bass[note]!,at+Double(s)*beat/4,0.69*strength,0)
                    }
                }
                if section != 4 && b>=6 && b<126 {
                    SourceDsp568.add(&main,perc["open"]!,at+beat/2,0.15*strength,(q%2==1 ? 1 : -1)*0.22)
                    for s in [1,3] {
                        SourceDsp568.add(&main,perc["closed"]!,at+Double(s)*beat/4,0.095*strength,(s==1 ? -1 : 1)*0.35)
                    }
                    if q==1 || q==3 {SourceDsp568.add(&main,perc["clap"]!,at,0.12*strength,0.05)}
                    if [2,3,5,6].contains(section) {
                        for s in 0..<4 {
                            SourceDsp568.add(&main,perc["shaker"]!,at+Double(s)*beat/4,
                                0.055*(0.75+rng.uniform()*0.5),(s%2==1 ? -1 : 1)*0.65)
                        }
                    }
                }
            }
            if b%4==0 {
                let padKey=[0,0,3,0,7,0,3,0][section]
                if pads[padKey]==nil {pads[padKey]=SourceDsp568.pad(key,voice,section,bar*4)}
                SourceDsp568.add(&space,pads[padKey]!,Double(b)*bar,breakdown ? 0.85 : 0.32)
            }
            if [1,2,3,5,6,7].contains(section) || !driving {
                for step in 0..<16 {
                    if step%4==0 || (step+b)%5==0 {continue}
                    let interval=patterns[v][(step+b/2+(b>=64 ? 3 : 0))%8]
                    let note=key+36+interval+(section==6 && step>11 ? 12 : 0)-(driving ? 0 : 12)
                    let idx=(step+b)%16,cache=note*16+idx
                    if acid[cache]==nil {
                        acid[cache]=v<5 ? SourceDsp568.acid(note,beat*0.64,idx,voice) : SourceDsp568.lead(note,beat*0.64,idx,v-5)
                    }
                    let at=Double(b)*bar+Double(step)*beat/4
                    let gain=(driving ? 0.105 : 0.078)*strength*(step%3==0 ? 0.7 : 1)
                    let pan=sin(Double(step)*1.3+Double(b)*0.2)*0.4
                    SourceDsp568.add(&main,acid[cache]!,at,gain,pan)
                    SourceDsp568.add(&delay,acid[cache]!,at,gain*0.6,-pan)
                }
            }
            if b%8==6 || b%8==7 {
                for p in 0..<4 {
                    SourceDsp568.add(&main,perc["tom"]!,Double(b)*bar+(3+Double(p)/4)*beat,
                        0.095*strength,(-1+Double(p)*0.67)*0.4)
                }
            }
            if b%8==7 {
                let dur=bar*2,count=Int(dur*r)
                let swell=SourceDsp568.noiseSwell(&rng,count)
                SourceDsp568.add(&space,swell,max(0,Double(b)*bar-dur+bar),0.7,0.15)
            }
        }
        for repeatIndex in 1..<6 {
            checkpoint()
            let shift=Int(beat*0.75*Double(repeatIndex)*r),gain=Float(pow(0.52,Double(repeatIndex)))
            for side in 0..<2 {
                let source=repeatIndex%2==1 ? (side==0 ? delay.right : delay.left) : (side==0 ? delay.left : delay.right)
                if shift<frames {
                    if side==0 {
                        for i in 0..<(frames-shift) {
                            if (i & 16383)==0 {checkpoint()}
                            main.left[shift+i]+=source[i]*gain
                        }
                    } else {
                        for i in 0..<(frames-shift) {
                            if (i & 16383)==0 {checkpoint()}
                            main.right[shift+i]+=source[i]*gain
                        }
                    }
                }
            }
        }
        for i in 0..<frames {
            if (i & 16383)==0 {checkpoint()}
            let duck=Float(SourceDsp568.sidechain(i,beat))
            space.left[i]*=duck;space.right[i]*=duck
        }
        let impulseFrames=Int(1.25*r)
        var impulse=SourceBus568(impulseFrames)
        for side in 0..<2 {
            var noise=[Float](repeating:0,count:impulseFrames)
            for i in noise.indices {noise[i]=Float(rng.normal()*exp(-Double(i)/(r*0.35)))}
            for i in 0..<Int(0.024*r) {noise[i]=0}
            var filtered=SourceDsp568.filtered(noise,"lowpass:6200")
            var energy:Float=0
            for v in filtered {energy += v*v}
            let divisor=sqrt(Double(energy))*4
            for i in filtered.indices {filtered[i]=Float(Double(filtered[i])/divisor)}
            let times:[Double]=[0.031,0.057,0.083], gains:[Double]=[0.18,0.14,0.09]
            for j in 0..<3 {filtered[Int((times[j]+Double(side)*0.004)*r)] += Float(gains[j])}
            if side==0 {impulse.left=filtered}else{impulse.right=filtered}
        }
        progress("Pogłos i przestrzeń stereo")
        for i in 0..<frames {
            if (i & 16383)==0 {checkpoint()}
            delay.left[i]=space.left[i]+delay.left[i]*0.23
            delay.right[i]=space.right[i]+delay.right[i]*0.23
        }
        SourceReverb568().render(delay,impulse:impulse,main:&main,space:space,
                                  progress:progress,checkpoint:checkpoint)
        // Release unused buses before mastering/writing the PCM file.
        delay=SourceBus568(0);space=SourceBus568(0);impulse=SourceBus568(0)
        main.left=SourceDsp568.filtered(main.left,"highpass:25",
                                         checkpoint:checkpoint)
        main.right=SourceDsp568.filtered(main.right,"highpass:25",
                                          checkpoint:checkpoint)
        progress("Mastering i przygotowanie pętli")
        try masterToWave(main,destination:destination,
                         checkpoint:checkpoint)
        return destination
    }
    private static func masterToWave(_ bus:SourceBus568,destination:URL,
                                     checkpoint:()->Void={})throws {
        let n=bus.left.count
        guard n>1,n==bus.right.count else{throw SynthError568.invalidPCM}
        var energy=0.0,peak=0.0
        // One global linear gain for the whole 128-bar song, exactly
        // MusicMaster.Render, not a sample-wise dynamic compressor.
        for i in 0..<n {
            if (i & 16383)==0 {checkpoint()}
            let intro=min(1,Double(i)/(Double(rate)*2.5))
            let outro=min(1,Double(n-1-i)/(Double(rate)*7))
            let edge=sin(intro*Double.pi/2)*sin(outro*Double.pi/2)
            for channel in [bus.left[i],bus.right[i]] {
                let value=Double(channel)*edge
                guard value.isFinite else{throw SynthError568.invalidPCM}
                energy+=value*value;peak=max(peak,abs(value))
            }
        }
        let rms=sqrt(energy/(Double(n)*2))
        let gain=peak==0 ? 0 : min(0.88/peak,0.145/max(rms,1e-12))
        let fm=FileManager.default
        _ = fm.createFile(atPath:destination.path,contents:nil)
        let file=try FileHandle(forWritingTo:destination)
        defer {try? file.close()}
        let byteCount=n*4
        guard byteCount<Int(UInt32.max)-44 else {throw SynthError568.invalidPCM}
        var header=Data()
        header.append(contentsOf:Array("RIFF".utf8))
        appendLE32(UInt32(36+byteCount),to:&header)
        header.append(contentsOf:Array("WAVEfmt ".utf8))
        appendLE32(16,to:&header)
        appendLE16(1,to:&header) // PCM, not pre-encoded AAC
        appendLE16(2,to:&header)
        appendLE32(UInt32(rate),to:&header)
        appendLE32(UInt32(rate*4),to:&header)
        appendLE16(4,to:&header)
        appendLE16(16,to:&header)
        header.append(contentsOf:Array("data".utf8))
        appendLE32(UInt32(byteCount),to:&header)
        try file.write(contentsOf:header)
        let frameChunk=8192
        var samples=[Int16](repeating:0,count:frameChunk*2)
        for base in stride(from:0,to:n,by:frameChunk) {
            // Never continue large PCM writes into active gameplay.
            checkpoint()
            let count=min(frameChunk,n-base)
            for j in 0..<count {
                let i=base+j
                let intro=min(1,Double(i)/(Double(rate)*2.5))
                let outro=min(1,Double(n-1-i)/(Double(rate)*7))
                let edge=sin(intro*Double.pi/2)*sin(outro*Double.pi/2)
                for side in 0..<2 {
                    let sample=Double(side==0 ? bus.left[i] : bus.right[i])*edge*gain*32768
                    var pcm=Int16(sample.rounded(.toNearestOrEven))
                    if i==0 || i==n-1 {pcm=0}
                    samples[j*2+side]=pcm.littleEndian
                }
            }
            try samples.withUnsafeBytes { ptr in
                try file.write(contentsOf:Data(ptr.prefix(count*4)))
            }
        }
    }
    private static func appendLE16(_ v:UInt16,to data:inout Data){var le=v.littleEndian;withUnsafeBytes(of:&le){data.append(contentsOf:$0)}}
    private static func appendLE32(_ v:UInt32,to data:inout Data){var le=v.littleEndian;withUnsafeBytes(of:&le){data.append(contentsOf:$0)}}
}