//
//  ClosedShapeTests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 05/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import XCTest

class ClosedShapeTests: XCTestCase
{
    func testStaticTransformVertices()
    {
        // Create a small box shape
        var shape = ClosedShape()
        
        shape.begin()
        shape.addVertex(Vector2(0, 0))
        shape.addVertex(Vector2(1, 0))
        shape.addVertex(Vector2.one)
        shape.addVertex(Vector2(0, 1))
        shape.finish(true)
        
        // Create the transformed shape with no modifications
        var transformed = shape.transformVertices(Vector2.zero, angleInRadians: 0, localScale: Vector2.one)
        
        // Assert that both shapes are equal
//        XCTAssertEqual(shape.localVertices[0] + Vector2.one, transformed[0], "The transformed shape is incorrect!")
//        XCTAssertEqual(shape.localVertices[1] + Vector2.one, transformed[1], "The transformed shape is incorrect!")
//        XCTAssertEqual(shape.localVertices[2] + Vector2.one, transformed[2], "The transformed shape is incorrect!")
//        XCTAssertEqual(shape.localVertices[3] + Vector2.one, transformed[3], "The transformed shape is incorrect!")
    }
    
    func testOffsetTransformVertices()
    {
        // Create a small box shape
        var shape = ClosedShape()
        
        shape.begin()
        shape.addVertex(Vector2(0, 0))
        shape.addVertex(Vector2(1, 0))
        shape.addVertex(Vector2.one)
        shape.addVertex(Vector2(0, 1))
        shape.finish(true)
        
        // Create the transformed shape with no modifications
        var transformed = shape.transformVertices(Vector2.one, angleInRadians: 0, localScale: Vector2.one)
        
        // Assert that both shapes are equal
        XCTAssertEqual(shape.localVertices[0] + Vector2.one, transformed[0], "The transformed shape is incorrect!")
        XCTAssertEqual(shape.localVertices[1] + Vector2.one, transformed[1], "The transformed shape is incorrect!")
        XCTAssertEqual(shape.localVertices[2] + Vector2.one, transformed[2], "The transformed shape is incorrect!")
        XCTAssertEqual(shape.localVertices[3] + Vector2.one, transformed[3], "The transformed shape is incorrect!")
    }
    
    func testRotateTransformVertices()
    {
        // Create a small box shape
        var shape = ClosedShape()
        
        shape.begin()
        shape.addVertex(Vector2(0, 0))
        shape.addVertex(Vector2(1, 0))
        shape.addVertex(Vector2.one)
        shape.addVertex(Vector2(0, 1))
        shape.finish(true)
        
        // Create the transformed shape with no modifications
        var transformed = shape.transformVertices(Vector2.one, angleInRadians: PI, localScale: Vector2.one)
        
        // Assert that both shapes are equal
        for i in 0..<shape.localVertices.count
        {
            //XCTAssertEqual(shape.localVertices[i], transformed[i], "The transformed shape is incorrect!")
        }
    }
}
