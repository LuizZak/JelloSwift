//
//  PhysicsMathTest.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 09/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import XCTest
import JelloSwift

class PhysicsMathTest: XCTestCase
{
    func testVector2Perp()
    {
        let vec1 = Vector2(x: 0, y: 1)
        let vecPerp = vec1.perpendicular()
        
        XCTAssert(vecPerp.x == -vec1.y && vecPerp.y == vec1.x, "Pass")
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
        XCTAssert(dis == sss, "Pass")
        XCTAssert(dissq == (dx * dx) + (dy * dy), "Pass")
    }
    
    func testVector2Math()
    {
        let vec1 = Vector2(x: 4, y: 6)
        let vec2 = Vector2(x: 9, y: 7)
        
        XCTAssert((vec1 • vec2) == JFloat(4 * 9 + 6 * 7), "DOT product test failed!")
        XCTAssert((vec1 =/ vec2) == JFloat(4 * 9 - 6 * 7), "CROSS product test failed!")
    }
    
    func testVector2Rotate()
    {
        //var vec = Vector2(x: 0, y: 1)
        
//        XCTAssertEqual(rotateVector(vec, PI * 2), vec, "Vector rotation test failed!")
//        XCTAssertEqual(rotateVector(vec, PI / 2), Vector2(-1,  0), "Vector rotation test failed!")
//        XCTAssertEqual(rotateVector(vec, PI)    , Vector2( 0, -1), "Vector rotation test failed!")
    }
}
