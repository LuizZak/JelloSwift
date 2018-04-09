//
//  BodyTests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 25/02/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import JelloSwift

class BodyTests: XCTestCase {
    
    static var allTests = [
        ("testPointNormalsNotANumber", testPointNormalsNotANumber)
    ]
    
    func testPointNormalsNotANumber() {
        // Tests the Body doesn't evaluate nan for point normals for edges
        // that are exactly overlapping one another
        
        // Make a shape with two parallel edges overlapping
        // Looks roughly like this:
        //  .___.__.
        //  |  /
        //  | /
        //  |/
        //  .
        //
        let shape = ClosedShape.create { shape in
            shape.addVertex(x: 0, y: 0)
            shape.addVertex(x: 1, y: 0)
            shape.addVertex(x: 0.5, y: 0)
            shape.addVertex(x: 0, y: 1)
        }
        
        let body = Body(world: nil, shape: shape)
        
        body.updateEdgesAndNormals()
        
        for point in body.pointMasses {
            XCTAssertFalse(point.normal.x.isNaN)
            XCTAssertFalse(point.normal.y.isNaN)
        }
    }
}
