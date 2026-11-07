import Foundation
import Metal

/// Three in-flight shared Metal frame arenas. We never overwrite a frame's
/// vertices/indices until its actual GPU command buffer completes.
/// Replaces per-frame new MTLBuffer allocations without reducing any
/// original source projectile, light, muzzle or destruction effects.
final class CarbonisFXStreamingBuffers568 {
    enum Role:Int,CaseIterable {
        case groundVertices,groundIndices,projectileVertices,
             projectileIndices,debrisVertices
    }
    private let gpu:MTLDevice
    private let inFlight=DispatchSemaphore(value:3)
    private var buffers:[[MTLBuffer?]]=Array(
        repeating:Array(repeating:nil,count:Role.allCases.count),count:3)
    private var slot = -1
    private(set) var uploadedBytes=0
    private(set) var allocations=0
    private let debug=ProcessInfo.processInfo.environment["ASTEROIDY_FX_PROFILE"]=="1"
    private var reportedAt=ProcessInfo.processInfo.systemUptime
    private var rollingUploads=0
    private var rollingAllocations=0

    init(device:MTLDevice){gpu=device}

    func beginFrame() {
        inFlight.wait()
        slot=(slot+1)%3
        uploadedBytes=0
        allocations=0
    }
    private static func capacity(_ requested:Int)->Int {
        var n=4096
        while n<requested {n*=2}
        return n
    }
    func upload<T>(_ elements:[T],as role:Role)->MTLBuffer? {
        guard slot>=0,!elements.isEmpty else{return nil}
        let length=elements.count*MemoryLayout<T>.stride
        let roleIndex=role.rawValue
        if (buffers[slot][roleIndex]?.length ?? 0)<length {
            guard let newBuffer=gpu.makeBuffer(length:Self.capacity(length),
                                               options:.storageModeShared)
            else {return nil}
            buffers[slot][roleIndex]=newBuffer
            allocations+=1
        }
        guard let target=buffers[slot][roleIndex] else{return nil}
        elements.withUnsafeBytes { bytes in
            if let pointer=bytes.baseAddress {
                target.contents().copyMemory(from:pointer,byteCount:length)
            }
        }
        uploadedBytes+=length
        return target
    }
    func completeFrame(_ command:MTLCommandBuffer) {
        // Capture the semaphore, not self; release on success/error alike.
        command.addCompletedHandler { [inFlight] _ in inFlight.signal() }
        if debug {
            rollingUploads+=uploadedBytes
            rollingAllocations+=allocations
            let time=ProcessInfo.processInfo.systemUptime
            if time-reportedAt>=5 {
                NSLog("ASTEROIDY_FX_PROFILE bytes5s=%d buffersCreated5s=%d",
                      rollingUploads,rollingAllocations)
                rollingUploads=0
                rollingAllocations=0
                reportedAt=time
            }
        }
    }
}
