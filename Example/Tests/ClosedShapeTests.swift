//
//  ClosedShapeTests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 05/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import XCTest
import JelloSwift

class ClosedShapeTests: XCTestCase {
    
    func testOffsetTransformVertices() {
        // Create a small box shape
        let shape = ClosedShape.create { (shape) in
            shape.addVertex(Vector2(x: 0, y: 0))
            shape.addVertex(Vector2(x: 1, y: 0))
            shape.addVertex(Vector2(x: 1, y: 1))
            shape.addVertex(Vector2(x: 0, y: 1))
        }
        
        // Create the transformed shape with no modifications
        let transformed = shape.transformedBy(translatingBy: Vector2.unit, rotatingBy: 0, scalingBy: Vector2.unit)
        
        // Assert that both shapes are equal
        XCTAssertEqual(shape.localVertices[0] + Vector2.unit, transformed[0])
        XCTAssertEqual(shape.localVertices[1] + Vector2.unit, transformed[1])
        XCTAssertEqual(shape.localVertices[2] + Vector2.unit, transformed[2])
        XCTAssertEqual(shape.localVertices[3] + Vector2.unit, transformed[3])
    }
    
    func testRotateTransformVertices() {
        // Create a small box shape
        let shape = ClosedShape.create { shape in
            shape.addVertex(Vector2(x: 0, y: 0))
            shape.addVertex(Vector2(x: 1, y: 0))
            shape.addVertex(Vector2(x: 1, y: 1))
            shape.addVertex(Vector2(x: 0, y: 1))
        }
        
        let expected = ClosedShape.create { shape in
            shape.addVertex(Vector2(x: 1, y: 1))
            shape.addVertex(Vector2(x: 0, y: 1))
            shape.addVertex(Vector2(x: 0, y: 0))
            shape.addVertex(Vector2(x: 1, y: 0))
        }
        
        // Create the transformed shape with no modifications
        let transformed = shape.transformedBy(translatingBy: Vector2.zero, rotatingBy: .pi, scalingBy: Vector2.unit)
        
        // Precision delta
        
        #if arch(x86_64) || arch(arm64)
            let delta: JFloat = 0.000000000000001
        #else
            let delta: JFloat = 0.0000001
        #endif
        
        // Since we rotated a box 90º, the edges are the same, but offset by 1.
        for i in 0..<expected.localVertices.count {
            let diff = expected.localVertices[i] - transformed[i]
            XCTAssert(diff.x < delta, "The transformed shape is incorrect!")
            XCTAssert(diff.y < delta, "The transformed shape is incorrect!")
        }
    }
    
    func testSquare() {
        let shape = ClosedShape.square(ofSide: 5)
        
        XCTAssertEqual(shape.localVertices[0].distance(to: shape.localVertices[1]), 5)
        XCTAssertEqual(shape.localVertices[1].distance(to: shape.localVertices[2]), 5)
        XCTAssertEqual(shape.localVertices[2].distance(to: shape.localVertices[3]), 5)
        XCTAssertEqual(shape.localVertices[3].distance(to: shape.localVertices[0]), 5)
        
        XCTAssertEqual(shape.localVertices.count, 4)
    }
    
    func testRectangle() {
        let shape = ClosedShape.rectangle(ofSides: Vector2(x: 2, y: 4))
        
        XCTAssertEqual(shape.localVertices[0].distance(to: shape.localVertices[1]), 2)
        XCTAssertEqual(shape.localVertices[1].distance(to: shape.localVertices[2]), 4)
        XCTAssertEqual(shape.localVertices[2].distance(to: shape.localVertices[3]), 2)
        XCTAssertEqual(shape.localVertices[3].distance(to: shape.localVertices[0]), 4)
        
        XCTAssertEqual(shape.localVertices.count, 4)
    }
    
    func testCircle() {
        let shape = ClosedShape.circle(ofRadius: 1, pointCount: 4)
        
        XCTAssert(shape[0].distance(to: shape[1]) - JFloat(2.squareRoot()) <= JFloat.leastNonzeroMagnitude) // There was a point in history in which some guys
        XCTAssert(shape[1].distance(to: shape[2]) - JFloat(2.squareRoot()) <= JFloat.leastNonzeroMagnitude) // drawing shapes in sand figured out the square root
        XCTAssert(shape[2].distance(to: shape[3]) - JFloat(2.squareRoot()) <= JFloat.leastNonzeroMagnitude) // of two using nothing but lines and circles. That's
        XCTAssert(shape[3].distance(to: shape[0]) - JFloat(2.squareRoot()) <= JFloat.leastNonzeroMagnitude) // a fun little fact that always puts a smile on my face.
        
        XCTAssertEqual(shape.localVertices.count, 4)
    }
    
    func testCircleSixPoints() {
        let shape = ClosedShape.circle(ofRadius: 1, pointCount: 8)
        
        // Verify all points lay the same distance to center, and are
        // approximately the same distance appart - that proves this is a circle
        let radi = shape[0].magnitude
        let dist = shape[0].distance(to: shape[1])
        
        var lastPoint = shape[7]
        for (i, p) in shape.localVertices.enumerated() {
            XCTAssert(p.magnitude - radi <= JFloat.leastNonzeroMagnitude, "Failed radius check on point \(i)")
            XCTAssert(p.distance(to: lastPoint) - dist <= 0.00000001, "Failed distance check on point \(i)")
            lastPoint = p
        }
        
        XCTAssertEqual(shape.localVertices.count, 8)
    }
    
    
}
