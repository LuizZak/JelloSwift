//
//  PhysicsMathTest.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 09/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import XCTest
import UIKit

class PhysicsMathTest: XCTestCase
{
    func testBitmask()
    {
        var p1 = Vector2(10, 20);
        var p2 = Vector2(300, 20);
        
        var v1 = Vector2(1, 2);
        var v2 = Vector2(2, 80);
        
        var force = calculateSpringForce(p1, v1, p2, v2, 20, 10, 1);
        
        println(force.toString());
        
        XCTAssert(true, "Pass")
    }
    
    func testVector2Perp()
    {
        var vec1 = Vector2(0, 1);
        var vecPerp = vec1.perpendicular();
        
        XCTAssert(vecPerp.X == -vec1.Y && vecPerp.Y == vec1.X, "Pass");
    }
    
    func testVector2Dist()
    {
        var vec1 = Vector2(4, 8);
        var vec2 = Vector2(14, 13);
        
        var dx: CGFloat = 4 - 14;
        var dy: CGFloat = 8 - 13;
        
        var dis = vec1.distance(vec2)
        var dissq = vec1.distanceSquared(vec2);
        var sss = sqrt((dx * dx) + (dy * dy));
        XCTAssert(dis == sss, "Pass");
        XCTAssert(dissq == (dx * dx) + (dy * dy), "Pass");
    }
    
    func testVector2Math()
    {
        var vec1 = Vector2(4, 6);
        var vec2 = Vector2(9, 7);
        
        XCTAssert((vec1 =* vec2) == CGFloat(4 * 9 + 6 * 7), "DOT product test failed!");
        XCTAssert((vec1 =/ vec2) == CGFloat(4 * 9 - 6 * 7), "CROSS product test failed!");
    }
    
    func testVector2Rotate()
    {
        var vec = Vector2(0, 1);
        
        XCTAssert(rotateVector(vec, 90)  != Vector2( 1,  0), "Vector rotation test failed!");
        XCTAssert(rotateVector(vec, 180) != Vector2( 0, -1), "Vector rotation test failed!");
    }
}