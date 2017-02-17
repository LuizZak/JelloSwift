//
//  AABBTests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 08/07/15.
//  Copyright © 2015 Luiz Fernando Silva. All rights reserved.
//

import XCTest
import JelloSwift

class AABBTests: XCTestCase {
    
    func testAABBWithPointsSimple() {
        // Tests AABB minimum/maximum coordinates calculation
        
        let point1 = Vector2(1, 2)
        let point2 = Vector2(10, 20)
        
        let aabb = AABB(points: [point1, point2])
        
        XCTAssert(aabb.minimum == Vector2(1, 2))
        XCTAssert(aabb.maximum == Vector2(10, 20))
    }
    
    func testAABBWithPointsMixed() {
        // Tests AABB minimum/maximum coordinates calculation
        // This test mixes minimum and maximum x and y axis between the
        // vectors
        
        let point1 = Vector2(10, 2)
        let point2 = Vector2(1, 20)
        
        let aabb = AABB(points: [point1, point2])
        
        XCTAssert(aabb.minimum == Vector2(1, 2))
        XCTAssert(aabb.maximum == Vector2(10, 20))
    }
    
    func testAABBIntersection() {
        //
        // Tests AABB intersection with a configuration:
        //  ___
        // |  _|_
        // |_|_| |
        //   |___|
        //
        
        let aabb1 = AABB(min: Vector2(0, 0), max: Vector2(10, 10))
        let aabb2 = AABB(min: Vector2(5, 5), max: Vector2(15, 15))
        
        XCTAssert(aabb1.intersects(aabb2))
    }
    
    func testAABBIntersectionSharingEdges() {
        //
        // Tests AABB intersection with a configuration:
        //  _______
        // |   |   |
        // |___|___|
        //
        // Sharing edge should be detected as intersection
        
        let aabb1 = AABB(min: Vector2(0, 0), max: Vector2(5, 5))
        let aabb2 = AABB(min: Vector2(5, 0), max: Vector2(10, 5))
        
        XCTAssert(aabb1.intersects(aabb2))
    }
    
    func testAABBComplexIntersection() {
        //
        // Tests AABB intersection with a configuration:
        //     ___
        //  __|___|__
        // |  |   |  |
        // |__|___|__|
        //    |___|
        //
        
        let aabb1 = AABB(min: Vector2(5, 0), max: Vector2(10, 15))
        let aabb2 = AABB(min: Vector2(0, 5), max: Vector2(15, 10))
        
        XCTAssert(aabb1.intersects(aabb2))
    }
    
    func testAABBNoIntersection() {
        //
        // Tests AABB intersection with a configuration:
        //  ___
        // |   |
        // |___| ___
        //      |   |
        //      |___|
        //
        // Should not report intersection!
        //
        
        let aabb1 = AABB(min: Vector2(0, 0), max: Vector2(10, 10))
        let aabb2 = AABB(min: Vector2(11, 11), max: Vector2(15, 15))
        
        XCTAssertFalse(aabb1.intersects(aabb2))
    }
    
    func testAABBNoIntersectionComplex() {
        //
        // Tests AABB intersection with a configuration:
        //   _____
        //  |     |
        //  |     |
        //  |_____| _____
        //         |     |
        //         |     |
        //         |_____|
        //
        // This is a mixture of complex AABB creation and non-intersection
        // detection.
        
        let aabb1 = AABB(min: Vector2(5, 0), max: Vector2(10, 10))
        let aabb2 = AABB(min: Vector2(6, 11), max: Vector2(14, 20))
        
        XCTAssertFalse(aabb1.intersects(aabb2))
    }
}
