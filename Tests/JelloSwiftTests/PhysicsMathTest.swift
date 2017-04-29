//
//  PhysicsMathTest.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 09/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import XCTest
@testable import JelloSwift

class PhysicsMathTest: XCTestCase
{
    static var allTests = [
        ("testVector2Perp", testVector2Perp),
        ("testVector2Dist", testVector2Dist),
        ("testVector2Math", testVector2Math)
    ]
    
    // Precision delta
    
    #if arch(x86_64) || arch(arm64)
        let delta: JFloat = 0.00000000000001
    #else
        let delta: JFloat = 0.000001
    #endif
    
    func testVector2Perp()
    {
        let vec1 = Vector2(x: 0, y: 1)
        let vecPerp = vec1.perpendicular()
        
        XCTAssert(abs(vecPerp.x - -vec1.y) <= delta && abs(vecPerp.y - vec1.x) <= delta, "Pass")
    }
    
    func testVector2Dist()
    {
        let vec1 = Vector2(x: 4, y: 8)
        let vec2 = Vector2(x: 14, y: 13)
        
        let dx: JFloat = 4 - 14
        let dy: JFloat = 8 - 13
        
        let dis = vec1.distance(to: vec2)
        let dissq = vec1.distanceSquared(to: vec2)
        let sss = sqrt((dx * dx) + (dy * dy))
        XCTAssert(abs(dis - sss) <= delta, "Pass")
        XCTAssert(abs(dissq - ((dx * dx) + (dy * dy))) <= delta, "Pass")
    }
    
    func testVector2Math()
    {
        let vec1 = Vector2(x: 4, y: 6)
        let vec2 = Vector2(x: 9, y: 7)
        
        XCTAssert(abs((vec1 • vec2) - JFloat(4 * 9 + 6 * 7)) <= delta, "DOT product test failed!")
        XCTAssert(abs((vec1 =/ vec2) - JFloat(4 * 9 - 6 * 7)) <= delta, "CROSS product test failed!")
    }
    
    func testVector2Rotate()
    {
        //var vec = Vector2(x: 0, y: 1)
        
//        XCTAssertEqual(rotateVector(vec, PI * 2), vec, "Vector rotation test failed!")
//        XCTAssertEqual(rotateVector(vec, PI / 2), Vector2(-1,  0), "Vector rotation test failed!")
//        XCTAssertEqual(rotateVector(vec, PI)    , Vector2( 0, -1), "Vector rotation test failed!")
    }
}
