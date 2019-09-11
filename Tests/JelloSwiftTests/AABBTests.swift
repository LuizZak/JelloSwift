//
//  AABBTests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 08/07/15.
//  Copyright © 2015 Luiz Fernando Silva. All rights reserved.
//

import XCTest
@testable import JelloSwift

class AABBTests: XCTestCase {
    
    static var allTests = [
        ("testAABBWithPointsSimple", testAABBWithPointsSimple),
        ("testAABBWithPointsMixed", testAABBWithPointsMixed),
        ("testAABBIntersection", testAABBIntersection),
        ("testAABBIntersectionSharingEdges", testAABBIntersectionSharingEdges),
        ("testAABBComplexIntersection", testAABBComplexIntersection),
        ("testAABBNoIntersection", testAABBNoIntersection),
        ("testAABBNoIntersectionComplex", testAABBNoIntersectionComplex)
    ]
    
    func testAABBWithPointsSimple() {
        // Tests AABB minimum/maximum coordinates calculation
        
        let point1 = Vector2(x: 1, y: 2)
        let point2 = Vector2(x: 10, y: 20)
        
        let aabb = AABB(points: [point1, point2])
        
        XCTAssert(aabb.minimum == Vector2(x: 1, y: 2))
        XCTAssert(aabb.maximum == Vector2(x: 10, y: 20))
    }
    
    func testAABBWithPointsMixed() {
        // Tests AABB minimum/maximum coordinates calculation
        // This test mixes minimum and maximum x and y axis between the
        // vectors
        
        let point1 = Vector2(x: 10, y: 2)
        let point2 = Vector2(x: 1, y: 20)
        
        let aabb = AABB(points: [point1, point2])
        
        XCTAssertEqual(aabb.minimum, Vector2(x: 1, y: 2))
        XCTAssertEqual(aabb.maximum, Vector2(x: 10, y: 20))
    }
    
    func testAABBIntersection() {
        //
        // Tests AABB intersection with a configuration:
        //  ___
        // |  _|_
        // |_|_| |
        //   |___|
        //
        
        let aabb1 = AABB(min: Vector2(x: 0, y: 0), max: Vector2(x: 10, y: 10))
        let aabb2 = AABB(min: Vector2(x: 5, y: 5), max: Vector2(x: 15, y: 15))
        
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
        
        let aabb1 = AABB(min: Vector2(x: 0, y: 0), max: Vector2(x: 5, y: 5))
        let aabb2 = AABB(min: Vector2(x: 5, y: 0), max: Vector2(x: 10, y: 5))
        
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
        
        let aabb1 = AABB(min: Vector2(x: 5, y: 0), max: Vector2(x: 10, y: 15))
        let aabb2 = AABB(min: Vector2(x: 0, y: 5), max: Vector2(x: 15, y: 10))
        
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
        
        let aabb1 = AABB(min: Vector2(x: 0, y: 0), max: Vector2(x: 10, y: 10))
        let aabb2 = AABB(min: Vector2(x: 11, y: 11), max: Vector2(x: 15, y: 15))
        
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
        
        let aabb1 = AABB(min: Vector2(x: 5, y: 0), max: Vector2(x: 10, y: 10))
        let aabb2 = AABB(min: Vector2(x: 6, y: 11), max: Vector2(x: 14, y: 20))
        
        XCTAssertFalse(aabb1.intersects(aabb2))
    }
}
