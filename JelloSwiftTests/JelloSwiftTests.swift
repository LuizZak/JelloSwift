//
//  JelloSwiftTests.swift
//  JelloSwiftTests
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import XCTest

class JelloSwiftTests: XCTestCase
{
    override func setUp()
    {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAABB()
    {
        var aabb1 = AABB(min: Vector2.Zero, max: Vector2(10, 10))
        var aabb2 = AABB(min: Vector2(-1, -1), max: Vector2(0, 0))
        var vec = Vector2(0, 0)
        
        // This is an example of a functional test case.
        XCTAssert(aabb1.contains(vec), "Pass")
        XCTAssert(aabb2.intersects(aabb1), "Pass")
    }
    
    func testBitmask()
    {
        var b:Bitmask = 0
        
        b = b +& 1
        b = b +& 2
        
        b = b +& 3
        b = b -& 3
        
        XCTAssert(b == 3, "Pass")
    }
    
    func testPerformanceExample()
    {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
            var t: [CGFloat] = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
            
            let c = t.count
            for i in 0..<100
            {
                for i in 0..<c
                {
                    t[i] = 0
                }
            }
        }
    }
}