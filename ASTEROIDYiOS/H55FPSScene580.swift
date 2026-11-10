import Foundation
import SceneKit
import GLTFKit2
import UIKit
import simd

/// Native, camera-relative PC580 first-person viewmodels.
/// Renders ACTUAL original source GLB meshes/materials; no replacement shapes.
/// The world still has one SceneKit renderer: high renderOrder & no world
/// depth-testing emulate Windows' separate viewmodel depth pass cheaply.
/// Camera/walking collisions, NPC, drones, H70 and the H51 compositor untouched.
@MainActor final class H55FPSScene580 {
    private weak var camera:SCNNode?
    private let fpsRoot=SCNNode()
    private let leftRoot=SCNNode()
    private let rightRoot=SCNNode()
    private let weaponRoot=SCNNode()
    private var loaded:Set<H55FPSAssets580.Kind>=[]
    private var loading:Set<H55FPSAssets580.Kind>=[]
    private var generation=UUID()
    private var settings=H55FPSSettings580()
    private var lastMotion:(time:Float,walking:Bool,bobPhase:Float,
                            bobAmount:Float,bobPercent:Float)?
    private let inform:(String)->Void

    init(camera:SCNNode,inform:@escaping(String)->Void) {
        self.camera=camera
        self.inform=inform
        fpsRoot.name="H55_PC580_FPS_VIEWMODEL"
        // SceneKit H55 camera FOV is 70°, original PC gloves and weapon 64°.
        // Scale positions/meshes by tan(35°)/tan(32°) to match frame coverage.
        let zoom:Float=1.1204
        fpsRoot.simdScale=SIMD3<Float>(repeating:zoom)
        leftRoot.name="PC_GLOVE_LEFT"
        rightRoot.name="PC_GLOVE_RIGHT"
        weaponRoot.name="PC_EXP01_WEAPON"
        fpsRoot.addChildNode(leftRoot)
        fpsRoot.addChildNode(rightRoot)
        fpsRoot.addChildNode(weaponRoot)
        camera.addChildNode(fpsRoot)
        fpsRoot.isHidden=true
        prepareCurrent()
    }

    func release() {
        generation=UUID()
        fpsRoot.removeFromParentNode()
        loaded.removeAll()
        loading.removeAll()
    }

    var mode:H55FPSSettings580.Mode {settings.mode}
    var gloveModel:H55FPSSettings580.Model {settings.model}
    var configuration:H55FPSSettings580 {settings}

    func calibrate(_ target:H55FPSSettings580.Target,component:Int,value:Int) {
        settings.calibrate(target,component:component,value:value)
        refreshLastPose()
    }
    func resetCalibration(_ target:H55FPSSettings580.Target) {
        settings.reset(target)
        refreshLastPose()
    }
    private func refreshLastPose() {
        guard let motion=lastMotion else{return}
        advance(time:motion.time,walking:motion.walking,
                bobPhase:motion.bobPhase,bobAmount:motion.bobAmount,
                bobPercent:motion.bobPercent)
    }

    func selectMode(_ mode:H55FPSSettings580.Mode) {
        settings.mode=mode
        settings.save()
        prepareCurrent()
    }
    func selectGloves(_ model:H55FPSSettings580.Model) {
        settings.changeModel(model)
        loaded.remove(.tripo)
        loaded.remove(.monolith)
        leftRoot.childNodes.forEach{$0.removeFromParentNode()}
        rightRoot.childNodes.forEach{$0.removeFromParentNode()}
        prepareCurrent()
    }
    func reload(_ kind:H55FPSAssets580.Kind) {
        loaded.remove(kind)
        if kind == .weapon {
            weaponRoot.childNodes.forEach{$0.removeFromParentNode()}
        } else {
            leftRoot.childNodes.forEach{$0.removeFromParentNode()}
            rightRoot.childNodes.forEach{$0.removeFromParentNode()}
        }
        prepareCurrent()
    }

    private func prepareCurrent() {
        let kind:H55FPSAssets580.Kind =
          settings.mode == .weapon ? .weapon :
            (settings.model == .tripo ? .tripo : .monolith)
        if loaded.contains(kind) {
            inform("FPS: ORYGINALNY MODEL \(kind.fileName) GOTOWY")
            return
        }
        if loading.contains(kind) {
            inform("FPS: TRWA ŁADOWANIE \(kind.fileName)")
            return
        }
        guard let url=H55FPSAssets580.installed(kind) else {
            inform("FPS: ZAIMPORTUJ ORYGINALNY \(kind.fileName) W MENU PAUZA")
            return
        }
        loading.insert(kind)
        inform("FPS: ŁADOWANIE \(kind.fileName) ...")
        let request=generation
        GLTFAsset.load(with:url,options:[:]) { [weak self] _,status,asset,error,_ in
            guard status == .complete || status == .error else{return}
            DispatchQueue.main.async {
                guard let self,self.generation==request else{return}
                self.loading.remove(kind)
                // An earlier asynchronous import must not overwrite the
                // currently selected TRIPO, MONOLIT or EXP-01 viewmodel.
                let selected:H55FPSAssets580.Kind = self.settings.mode == .weapon
                    ? .weapon : (self.settings.model == .tripo ? .tripo : .monolith)
                guard kind == selected else{return}
                guard status == .complete,let asset else {
                    let failure=error?.localizedDescription ?? "GLTFKit2"
                    self.inform("FPS: BŁĄD DEKODOWANIA ORYGINAŁU \(kind.fileName): \(failure)")
                    return
                }
                let source=GLTFSCNSceneSource(asset:asset)
                guard self.bindSource(source,kind:kind) else {
                    self.inform("FPS: NIEZGODNE WĘZŁY ORYGINALNEGO MODELU \(kind.fileName)")
                    return
                }
                self.loaded.insert(kind)
                self.inform("FPS: \(kind == .weapon ? "BROŃ EXP-01" : "RĘCE GLB") GOTOWE")
            }
        }
    }

    private func protectMaterials(_ node:SCNNode) {
        node.enumerateHierarchy { n,_ in
            if let geo=n.geometry {
                n.renderingOrder=1000
                for material in geo.materials {
                    // The source's PBR/UV/vertex colours remain unchanged.
                    // Original PC weapon/gloves run a separate 64-degree
                    // depth pass on top of the 3D hangar.
                    material.readsFromDepthBuffer=false
                    material.writesToDepthBuffer=false
                    material.isDoubleSided=true
                }
            }
        }
    }
    private func bindSource(_ source:GLTFSCNSceneSource,
                            kind:H55FPSAssets580.Kind)->Bool {
        guard let scene=source.defaultScene else{return false}
        if kind == .weapon {
            let nodes=scene.rootNode.childNodes
            guard !nodes.isEmpty,
                  source.nodes.filter({$0.geometry != nil}).count>30 else{return false}
            weaponRoot.childNodes.forEach{$0.removeFromParentNode()}
            // Keep ALL original EXP-01 parts, hierarchy, PBR and sockets.
            for node in nodes {
                let copy=node.clone()
                protectMaterials(copy)
                weaponRoot.addChildNode(copy)
            }
            return !weaponRoot.childNodes.isEmpty
        }
        // Source PC580 baked VBO splits each TRIANGLE, not whole GLB nodes.
        // MONOLIT uses Y and reverses anatomical mapping. Reuse the
        // existing vertex/normal/UV/material sources for both hands.
        guard let split=try? H55FPSMeshSplit580.build(scene:scene,kind:kind)
        else{return false}
        leftRoot.childNodes.forEach{$0.removeFromParentNode()}
        rightRoot.childNodes.forEach{$0.removeFromParentNode()}
        for node in split.left {
            protectMaterials(node)
            leftRoot.addChildNode(node)
        }
        for node in split.right {
            protectMaterials(node)
            rightRoot.addChildNode(node)
        }
        inform("FPS: RĘCE \(kind.fileName): \(split.triangles) ORYGINALNYCH TRÓJKĄTÓW")
        return true
    }

    private func orientation(_ x:Float,_ y:Float,_ z:Float)->simd_quatf {
        let rad=Float.pi/180
        let rx=simd_quatf(angle:x*rad,axis:SIMD3<Float>(1,0,0))
        let ry=simd_quatf(angle:y*rad,axis:SIMD3<Float>(0,1,0))
        let rz=simd_quatf(angle:z*rad,axis:SIMD3<Float>(0,0,1))
        return rx*ry*rz
    }

    func advance(time:Float,walking:Bool,bobPhase:Float,bobAmount:Float,
                 bobPercent:Float=50) {
        lastMotion=(time,walking,bobPhase,bobAmount,bobPercent)
        fpsRoot.isHidden = !walking
        guard walking else{return}
        let movement=settings.bob ? bobAmount : 0
        let intensity=max(0,min(1,bobPercent/100))
        if settings.mode == .gloves {
            weaponRoot.isHidden=true
            leftRoot.isHidden=false
            rightRoot.isHidden=false
            for hand in 0..<2 {
                let root=hand==0 ? leftRoot : rightRoot
                let pose=hand==0 ? settings.left : settings.right
                let sway=H55FPSPose580.gloveWalk(phase:bobPhase,
                            movement:movement,visualIntensity:intensity,hand:hand)
                let idle=H55FPSPose580.idle(time:time,hand:hand,
                                             enabled:settings.idle)
                root.simdPosition=SIMD3<Float>(
                    Float(pose[0])*0.01+sway.x,
                    Float(pose[1])*0.01+sway.y+idle,
                    Float(pose[2])*0.01)
                // PC ApplyGlovePose422: extra yaw *before* rotations XYZ.
                let walkingYaw=simd_quatf(angle:sway.yawDegrees*Float.pi/180,
                             axis:SIMD3<Float>(0,1,0))
                let handRotation=orientation(Float(pose[3]),Float(pose[4]),Float(pose[5]))
                root.simdOrientation=walkingYaw*handRotation
                let scale=max(0.25,min(2.5,Float(pose[6])*0.01))
                root.simdScale=SIMD3<Float>(repeating:scale)
            }
        } else {
            leftRoot.isHidden=true
            rightRoot.isHidden=true
            weaponRoot.isHidden=false
            let p=settings.weapon
            let sway=H55FPSPose580.weaponWalk(phase:bobPhase,
                            movement:movement,visualIntensity:intensity)
            let idleVertical=H55FPSPose580.weaponIdle(time:time,enabled:settings.idle)
            let vertical=Float(p[1])*0.01+sway.y+idleVertical
            weaponRoot.simdPosition=SIMD3<Float>(
                Float(p[0])*0.01+sway.x,vertical,Float(p[2])*0.01)
            let x=simd_quatf(angle:-Float.pi/2,axis:SIMD3<Float>(1,0,0))
            let z=simd_quatf(angle:Float.pi/2,axis:SIMD3<Float>(0,0,1))
            let rotation=orientation(Float(p[3]),Float(p[4])+sway.yawDegrees,Float(p[5]))
            weaponRoot.simdOrientation=x*z*rotation
            let userScale=max(0.25,min(2.5,Float(p[6])*0.01))
            let scale=H55FPSPose580.weaponScale*userScale
            weaponRoot.simdScale=SIMD3<Float>(repeating:scale)
        }
    }
}
