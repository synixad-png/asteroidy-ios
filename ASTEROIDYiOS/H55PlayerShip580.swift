import Foundation
import SceneKit
import UIKit
import CryptoKit
import simd

/// Windows GpuHub90.DrawFighterMesh uses the current real craft, not a mesh
/// within hangar_h55.glb. iOS currently ports the default ShipType=1:
/// original Vanguard431 .mesh and matching JPEG already in the app.
@MainActor enum H55PlayerShip580 {
    static let nodeName="H55_PC580_VANGUARD431_SHIP"
    enum Error:Swift.Error {case missing,invalidSource,invalidTexture,notTriangles}

    private static func resource(_ name:String,_ ext:String)->URL? {
        Bundle.main.url(forResource:name,withExtension:ext) ??
          Bundle.main.url(forResource:name,withExtension:ext,subdirectory:"Assets")
    }
    private static func hash(_ data:Data)->String {
        SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()
    }
    private static func loadGeometry() throws -> SCNGeometry {
        guard let meshURL=resource("Vanguard431Source","mesh"),
              let skinURL=resource("Vanguard431Base","jpg"),
              let bytes=try? Data(contentsOf:meshURL),
              let skinBytes=try? Data(contentsOf:skinURL)
        else{throw Error.missing}
        guard hash(bytes)==SourceVanguardMesh431.exactMeshSHA256,
              let original=try? SourceVanguardMesh431(data:bytes)
        else{throw Error.invalidSource}
        guard hash(skinBytes)==SourceVanguardMesh431.exactBaseJPEG_SHA256,
              let image=UIImage(data:skinBytes)
        else{throw Error.invalidTexture}
        let count=original.vertexCount
        guard count>0 && count%3==0 else{throw Error.notTriangles}
        // GPU [XYZ, normalXYZ, RGBA, UV] = 12 Float32/vertex.
        // Interleaved sources share ONE verified source Data allocation.
        func stream(_ kind:SCNGeometrySource.Semantic,_ offset:Int,
                    _ components:Int)->SCNGeometrySource {
            SCNGeometrySource(data:original.vertices,semantic:kind,
                 vectorCount:count,usesFloatComponents:true,
                 componentsPerVector:components,bytesPerComponent:4,
                 dataOffset:offset,dataStride:48)
        }
        let indices=(0..<count).map{UInt32($0)}
        let indexData=indices.withUnsafeBytes{Data($0)}
        let element=SCNGeometryElement(data:indexData,
             primitiveType:.triangles,primitiveCount:count/3,bytesPerIndex:4)
        let result=SCNGeometry(sources:[
            stream(.vertex,0,3),
            stream(.normal,12,3),
            stream(.color,24,4),
            stream(.texcoord,40,2)
        ],elements:[element])
        let material=SCNMaterial()
        material.name="Vanguard431_source_mesh_and_base_JPEG"
        material.lightingModel = .physicallyBased
        material.diffuse.contents=image
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        material.metalness.contents=0.16
        material.roughness.contents=0.48
        material.isDoubleSided=true
        result.materials=[material]
        return result
    }
    /// Source mesh is cached and shared across repeated H55 entries,
    /// not decoded with every arrival or every animation frame.
    private static let sourceGeometry:SCNGeometry? = try? loadGeometry()

    static func make()->SCNNode? {
        guard let geometry=sourceGeometry else{return nil}
        let result=SCNNode(geometry:geometry)
        result.name=nodeName
        // PC GpuHub90.cs standard ship scale 2.35, default Vanguard.
        result.scale=SCNVector3(2.35,2.35,2.35)
        pose(result,time:0)
        return result
    }

    static func pose(_ node:SCNNode,time:Float) {
        let frame=H55DockingPresentation580.ship(time:time)
        node.position=SCNVector3(frame.x,frame.y,frame.z)
        // PC order: shipRotate(Y) then shipRotate(-90,X).
        node.simdOrientation=simd_quatf(
             angle:frame.yaw,axis:SIMD3<Float>(0,1,0)) *
             simd_quatf(angle:-Float.pi/2,axis:SIMD3<Float>(1,0,0))
    }
}
