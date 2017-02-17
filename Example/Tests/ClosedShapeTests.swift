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

class ClosedShapeTests: XCTestCase
{
    func testOffsetTransformVertices()
    {
        // Create a small box shape
        let shape = ClosedShape.create { (shape) in
            shape.addVertex(Vector2(0, 0))
            shape.addVertex(Vector2(1, 0))
            shape.addVertex(Vector2(1, 1))
            shape.addVertex(Vector2(0, 1))
        }
        
        // Create the transformed shape with no modifications
        let transformed = shape.transformedBy(translatingBy: Vector2.unit, rotatingBy: 0, scalingBy: Vector2.unit)
        
        // Assert that both shapes are equal
        XCTAssertEqual(shape.localVertices[0] + Vector2.unit, transformed[0], "The transformed shape is incorrect!")
        XCTAssertEqual(shape.localVertices[1] + Vector2.unit, transformed[1], "The transformed shape is incorrect!")
        XCTAssertEqual(shape.localVertices[2] + Vector2.unit, transformed[2], "The transformed shape is incorrect!")
        XCTAssertEqual(shape.localVertices[3] + Vector2.unit, transformed[3], "The transformed shape is incorrect!")
    }
    
    func testRotateTransformVertices()
    {
        // Create a small box shape
        let shape = ClosedShape.create { shape in
            shape.addVertex(Vector2(0, 0))
            shape.addVertex(Vector2(1, 0))
            shape.addVertex(Vector2(1, 1))
            shape.addVertex(Vector2(0, 1))
        }
        
        let expected = ClosedShape.create { shape in
            shape.addVertex(Vector2(1, 1))
            shape.addVertex(Vector2(0, 1))
            shape.addVertex(Vector2(0, 0))
            shape.addVertex(Vector2(1, 0))
        }
        
        // Create the transformed shape with no modifications
        let transformed = shape.transformedBy(translatingBy: Vector2.zero, rotatingBy: .pi, scalingBy: Vector2.unit)
        
        // Since we rotated a box 90º, the edges are the same, but offset by 1.
        for i in 0..<expected.localVertices.count
        {
            XCTAssertEqual(expected.localVertices[i], transformed[i], "The transformed shape is incorrect!")
        }
    }
}
