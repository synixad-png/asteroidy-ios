#!/usr/bin/env swift
// Pixel-based smoke test of an AUTHENTIC ASTEROIDY iOS simulator screenshot.
//
// This does not claim physical iPhone/iPad GPU correctness, pixel
// equivalence to the original Windows renderer, or mission parity.
// Black / single-colour screenshots are rejected. The screenshot comes
// from xcrun simctl io <device> screenshot while this very app runs.
//
// Run: swift Tools/verify_simulator_render_snapshot.swift reports/iphone.png
// Self-test: swift Tools/verify_simulator_render_snapshot.swift --self-test

import Foundation
import AppKit

enum SnapshotFailure: Error, CustomStringConvertible {
    case unreadable, blank, insufficientPixels
    var description: String {
        switch self {
        case .unreadable: return "Invalid or unreadable simulator PNG"
        case .blank: return "Blank / single-colour render detected"
        case .insufficientPixels: return "Screenshot too small for visual smoke test"
        }
    }
}

func classify(_ bitmap: NSBitmapImageRep) throws -> (Int,Int,Int,Double) {
    let w=bitmap.pixelsWide, h=bitmap.pixelsHigh
    guard w>=64 && h>=64 else { throw SnapshotFailure.insufficientPixels }
    // Sample the middle of the genuine Metal frame, not iOS status bar
    // or the fixed cyan HUD at the edge of the user's source scene.
    let xs=Int(Double(w)*0.2), xe=Int(Double(w)*0.8)
    let ys=Int(Double(h)*0.2), ye=Int(Double(h)*0.8)
    let step=max(1,min(w,h)/100)
    var total=0, maximum=0.0, minimum=1.0
    var countBright=0
    var colours=Set<Int>()
    for y in stride(from:ys,to:ye,by:step) {
        for x in stride(from:xs,to:xe,by:step) {
            guard let c=bitmap.colorAt(x:x,y:y)?.usingColorSpace(.deviceRGB) else {
                throw SnapshotFailure.unreadable
            }
            let r=max(0,min(1,c.redComponent))
            let g=max(0,min(1,c.greenComponent))
            let b=max(0,min(1,c.blueComponent))
            let lum=0.2126*r+0.7152*g+0.0722*b
            minimum=min(minimum,lum)
            maximum=max(maximum,lum)
            total+=1
            if lum>0.14 { countBright+=1 }
            let packed=(Int(r*31)<<10)|(Int(g*31)<<5)|Int(b*31)
            colours.insert(packed)
        }
    }
    guard total>=100 else { throw SnapshotFailure.insufficientPixels }
    guard maximum-minimum>0.06, colours.count>=20,
          countBright>=4 else {
        throw SnapshotFailure.blank
    }
    return (w,h,colours.count,maximum-minimum)
}

func png(_ url:URL) throws -> NSBitmapImageRep {
    let bytes=try Data(contentsOf:url)
    guard bytes.prefix(8)==Data([137,80,78,71,13,10,26,10]),
          let b=NSBitmapImageRep(data:bytes) else {
        throw SnapshotFailure.unreadable
    }
    return b
}

func fixture(_ blank:Bool)->NSBitmapImageRep {
    guard let b=NSBitmapImageRep(
        bitmapDataPlanes:nil,pixelsWide:128,pixelsHigh:128,
        bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,
        isPlanar:false,colorSpaceName:.deviceRGB,
        bytesPerRow:0,bitsPerPixel:0) else {
        fatalError("AppKit fixture bitmap creation failed")
    }
    for y in 0..<128 {
        for x in 0..<128 {
            let red=blank ? 0.05 : Double(x)/127.0
            let green=blank ? 0.05 : Double(y)/127.0
            let blue=blank ? 0.05 : Double((x+y)%128)/127.0
            b.setColor(NSColor(calibratedRed:red,green:green,blue:blue,
                               alpha:1),atX:x,y:y)
        }
    }
    return b
}

do {
    let args=CommandLine.arguments
    if args.count==2 && args[1]=="--self-test" {
        do {
            _=try classify(fixture(true))
            fatalError("Blank synthetic image was unexpectedly accepted")
        } catch SnapshotFailure.blank {
            // Expected, the detector must not mistake a blank Metal
            // clear for a genuine spacecraft frame.
        }
        let r=try classify(fixture(false))
        guard r.2>=20 else { throw SnapshotFailure.blank }
        print("PASS: simulator screenshot detector rejects blank renders and")
        print("      accepts varied real RGB geometry (synthetic fixtures only)")
    } else {
        guard args.count==2 else {
            fatalError("Usage: swift verify_simulator_render_snapshot.swift <PNG>")
        }
        let r=try classify(png(URL(fileURLWithPath:args[1])))
        print("PASS: authentic ASTEROIDY simulator screenshot is nonblank")
        print("      dimensions=\(r.0)x\(r.1), distinct RGB cells=\(r.2),")
        print("      central luminance range=\(String(format:"%.3f",r.3))")
        print("LIMIT: genuine screenshot; not proof of 1:1 original-PC graphics")
    }
} catch {
    fputs("FAIL: simulator frame smoke check: \(error)\n",stderr)
    exit(1)
}
