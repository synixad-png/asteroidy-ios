import XCTest
import Foundation
@testable import ASTEROIDYiOS

final class BoreasMorphOptimization556Tests: XCTestCase {
    private func load(_ name: String, _ ext: String) throws -> Data {
        let url = Bundle.main.url(forResource:name, withExtension:ext)
              ?? Bundle.main.url(forResource:name, withExtension:ext, subdirectory:"Assets")
        return try Data(contentsOf:XCTUnwrap(url))
    }
    func testOptimizedNormalsEqualFullRecompute() throws {
        let mesh = try AssetMesh(data:load("Boreas556", "as3d"))
        let source = try BoreasMorph556(data:load("Boreas556", "asmo"))
        let anim = try BoreasMorphRenderer556(source:source,
            bindingData:load("BoreasMorphBinding556", "json"), mesh:mesh)
        for second in [0.0, 0.125, 1.25, 2.5, 4.99, 5.0] {
            let output = anim.animatedVertices(seconds:second)
            let reference = AssetMesh.computeNormals(vertices:output,indices:mesh.indices)
            for i in output.indices {
                let n = output[i].normal, r = reference[i]
                XCTAssertLessThan(abs(n.x-r.x)+abs(n.y-r.y)+abs(n.z-r.z), 0.00001,
                                  "normal mismatch: vertex \(i), t=\(second)")
            }
        }
    }
    func testReusableScratchMatchesBaselineAcrossCycles() throws {
        let mesh = try AssetMesh(data:load("Boreas556", "as3d"))
        let source = try BoreasMorph556(data:load("Boreas556", "asmo"))
        let anim = try BoreasMorphRenderer556(source:source,
            bindingData:load("BoreasMorphBinding556", "json"), mesh:mesh)
        var scratch = anim.makeScratchVertices()
        let staticCount = anim.dynamicVertexRange.lowerBound
        XCTAssertEqual(staticCount, 4320)
        for t in [0.0, 0.1, 0.55, 1.2, 3.9, 4.99, 5.0, 8.25, 0.4] {
            anim.updateVertices(seconds:t, into:&scratch)
            let reference = anim.animatedVertices(seconds:t)
            XCTAssertEqual(scratch.count, reference.count)
            for i in scratch.indices {
                XCTAssertEqual(scratch[i].position, reference[i].position)
                XCTAssertEqual(scratch[i].normal, reference[i].normal)
            }
            for i in 0..<staticCount {
                XCTAssertEqual(scratch[i].position, mesh.vertices[i].position)
                XCTAssertEqual(scratch[i].normal, mesh.vertices[i].normal)
            }
        }
    }

}
