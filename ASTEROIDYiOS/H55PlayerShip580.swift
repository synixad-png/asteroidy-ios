import Foundation
import SceneKit
import UIKit
import CryptoKit
import simd

/// One original PC baked-GLB scene geometry path for the two supported
/// playable ships. H55 draws the equipped ship OUTSIDE hangar_h55.glb.
@MainActor enum H55PlayerShip580 {
    static let nodeName="H55_PC580_VANGUARD431_SHIP"
    static let bastionNodeName="H55_PC606_BASTION_SHIP"
    enum Error:Swift.Error {case missing,invalidSource,invalidTexture,notTriangles}

    private static func resource(_ name:String,_ ext:String)->URL? {
        Bundle.main.url(forResource:name,withExtension:ext) ??
          Bundle.main.url(forResource:name,withExtension:ext,subdirectory:"Assets")
    }
    private static func hash(_ data:Data)->String {
        SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()
    }

    /// Both original PC meshes use precisely the same 12-Float32 ABI.
    /// Build one indexed SceneKit geometry, preserving winding, UV and
    /// normals. No GLB re-bake, simplification or substitute hull.
    private static func geometry(_ mesh:SourceBakedShipMesh,
                                 image:UIImage,name:String,
                                 baseFactor:CGFloat)->SCNGeometry? {
        let count=mesh.vertexCount
        guard count>0 && count%3==0 else{return nil}
        func stream(_ kind:SCNGeometrySource.Semantic,_ offset:Int,
                    _ components:Int)->SCNGeometrySource {
            SCNGeometrySource(data:mesh.vertices,semantic:kind,
                 vectorCount:count,usesFloatComponents:true,
                 componentsPerVector:components,bytesPerComponent:4,
                 dataOffset:offset,dataStride:48)
        }
        let indices=(0..<count).map{UInt32($0)}
        let indexData=indices.withUnsafeBytes{Data($0)}
        let element=SCNGeometryElement(data:indexData,
             primitiveType:.triangles,primitiveCount:count/3,bytesPerIndex:4)
        let result=SCNGeometry(sources:[
            stream(.vertex,0,3),stream(.normal,12,3),
            stream(.color,24,4),stream(.texcoord,40,2)
        ],elements:[element])
        let material=SCNMaterial()
        material.name=name
        material.lightingModel = .physicallyBased
        material.diffuse.contents=image
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        material.multiply.contents=UIColor(white:baseFactor,alpha:1)
        material.metalness.contents=0.16
        material.roughness.contents=0.48
        material.isDoubleSided=true
        result.materials=[material]
        return result
    }

    private static func loadVanguard() throws ->SCNGeometry {
        guard let meshURL=resource("Vanguard431Source","mesh"),
              let skinURL=resource("Vanguard431Base","jpg"),
              let bytes=try? Data(contentsOf:meshURL),
              let skinBytes=try? Data(contentsOf:skinURL)
        else{throw Error.missing}
        guard hash(bytes)==SourceVanguardMesh431.exactMeshSHA256,
              let original=try? SourceBakedShipMesh(data:bytes)
        else{throw Error.invalidSource}
        guard hash(skinBytes)==SourceVanguardMesh431.exactBaseJPEG_SHA256,
              let image=UIImage(data:skinBytes)
        else{throw Error.invalidTexture}
        guard let result=geometry(original,image:image,
             name:"Vanguard431_source_mesh_and_base_JPEG",baseFactor:1)
        else{throw Error.notTriangles}
        return result
    }

    private static func loadBastion() throws ->SCNGeometry {
        guard let asset=SourceBastion606.load(),
              let image=UIImage(data:asset.jpeg)
        else{throw Error.missing}
        guard let result=geometry(asset.mesh,image:image,
             name:"Bastion606_PC609_GLTF_BaseColor",baseFactor:0.8)
        else{throw Error.notTriangles}
        return result
    }

    /// Immutable original models, independently resident at most once.
    /// A missing Bastion is never silently replaced with Vanguard.
    private static let vanguardGeometry:SCNGeometry?=try? loadVanguard()
    private static var bastionGeometry:SCNGeometry?

    static func make()->SCNNode? {
        let selected=H55SourceMechanics580.load().selectedShip
        let chosen:SCNGeometry?
        switch selected {
        case 1:chosen=vanguardGeometry
        case 2:
            if bastionGeometry==nil {bastionGeometry=try? loadBastion()}
            chosen=bastionGeometry
        default:return nil
        }
        guard let chosen else{return nil}
        let result=SCNNode(geometry:chosen)
        result.name=selected==2 ? bastionNodeName : nodeName
        // Same native PC Hub90 fighter transform for all baked ships.
        result.scale=SCNVector3(2.35,2.35,2.35)
        pose(result,time:0)
        return result
    }

    static func pose(_ node:SCNNode,time:Float) {
        let frame=H55DockingPresentation580.ship(time:time)
        node.position=SCNVector3(frame.x,frame.y,frame.z)
        node.simdOrientation=simd_quatf(
             angle:frame.yaw,axis:SIMD3<Float>(0,1,0)) *
             simd_quatf(angle:-Float.pi/2,axis:SIMD3<Float>(1,0,0))
    }
}
