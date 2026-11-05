import XCTest
import Foundation
@testable import ASTEROIDYiOS

final class BoreasMorphBinding556Tests: XCTestCase {
    private func load(_ filename: String, _ ext: String) throws -> Data {
        let url = Bundle.main.url(forResource:filename, withExtension:ext)
              ?? Bundle.main.url(forResource:filename, withExtension:ext, subdirectory:"Assets")
        return try Data(contentsOf: XCTUnwrap(url))
    }
    func testBindingAndDeformation() throws {
        let asset = try AssetMesh(data:load("Boreas556","as3d"))
        let morph = try BoreasMorph556(data:load("Boreas556","asmo"))
        let animation = try BoreasMorphRenderer556(source:morph,
            bindingData:load("BoreasMorphBinding556","json"),mesh:asset)
        let zero = animation.animatedVertices(seconds:0)
        let quarter = animation.animatedVertices(seconds:1.25)
        XCTAssertEqual(zero.count, 31355)
        XCTAssertEqual(quarter.count, zero.count)
        XCTAssertTrue(zip(zero,quarter).contains { a,b in
            abs(a.position.x-b.position.x) + abs(a.position.y-b.position.y) + abs(a.position.z-b.position.z) > 0.00001
        })
        let repeatFrame = animation.animatedVertices(seconds:5)
        XCTAssertEqual(zero[5000].position, repeatFrame[5000].position)
    }
}
