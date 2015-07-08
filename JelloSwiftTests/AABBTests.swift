//
//  AABBTests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 08/07/15.
//  Copyright © 2015 Luiz Fernando Silva. All rights reserved.
//

import XCTest

class AABBTests: XCTestCase {
    
    func testAABBWithPointsSimple() {
        let point1 = Vector2(1, 2)
        let point2 = Vector2(10, 20)
        
        let aabb = AABB(points: [point1, point2])
        
        XCTAssert(aabb.minimum == Vector2(1, 2))
        XCTAssert(aabb.maximum == Vector2(10, 20))
    }
    
    func testAABBWithPointsMixed() {
        let point1 = Vector2(10, 2)
        let point2 = Vector2(1, 20)
        
        let aabb = AABB(points: [point1, point2])
        
        XCTAssert(aabb.minimum == Vector2(1, 2))
        XCTAssert(aabb.maximum == Vector2(10, 20))
    }
    
    func testAABBIntersection() {
        let aabb1 = AABB(min: Vector2(0, 0), max: Vector2(10, 10))
        let aabb2 = AABB(min: Vector2(5, 5), max: Vector2(15, 15))
        
        XCTAssert(aabb1.intersects(aabb2))
    }
    
    func testAABBComplexIntersection() {
        let aabb1 = AABB(min: Vector2(5, 0), max: Vector2(10, 15))
        let aabb2 = AABB(min: Vector2(0, 5), max: Vector2(15, 10))
        
        XCTAssert(aabb1.intersects(aabb2))
    }
    
    func testAABBNoIntersection() {
        let aabb1 = AABB(min: Vector2(0, 0), max: Vector2(10, 10))
        let aabb2 = AABB(min: Vector2(11, 11), max: Vector2(15, 15))
        
        XCTAssert(!aabb1.intersects(aabb2))
    }
    
    func testAABBNoIntersectionComplex() {
        let aabb1 = AABB(min: Vector2(5, 0), max: Vector2(10, 10))
        let aabb2 = AABB(min: Vector2(6, 11), max: Vector2(14, 20))
        
        XCTAssert(!aabb1.intersects(aabb2))
    }
}
