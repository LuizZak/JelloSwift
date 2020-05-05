//
//  JelloSwiftTests.swift
//  JelloSwiftTests
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import XCTest
@testable import JelloSwift

class JelloSwiftTests: XCTestCase {
    func testAABB() {
        let aabb1 = AABB(min: Vector2.zero, max: Vector2(x: 10, y: 10))
        let aabb2 = AABB(min: Vector2(x: -1, y: -1), max: Vector2(x: 0, y: 0))
        let vec = Vector2(x: 0, y: 0)
        
        // This is an example of a functional test case.
        XCTAssert(aabb1.contains(vec), "Pass")
        XCTAssert(aabb2.intersects(aabb1), "Pass")
    }
    
    func testBitmask() {
        var b:Bitmask = 0
        
        b = b.setBitOn(atIndex: 1)
        b = b.setBitOn(atIndex: 2)
        
        b = b.setBitOn(atIndex: 3)
        b = b.setBitOff(atIndex: 3)
        
        XCTAssert(b == 3, "Pass")
    }
}
