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
    func testStaticTransformVertices()
    {
        // Create a small box shape
        var shape = ClosedShape()
        
        shape.begin()
        shape.addVertex(Vector2(0, 0))
        shape.addVertex(Vector2(1, 0))
        shape.addVertex(Vector2.unit)
        shape.addVertex(Vector2(0, 1))
        shape.finish(recentering: true)
        
        // Create the transformed shape with no modifications
        //var transformed = shape.transformVertices(Vector2.zero, angleInRadians: 0, localScale: Vector2.unit)
        
        // Assert that both shapes are equal
//        XCTAssertEqual(shape.localVertices[0] + Vector2.unit, transformed[0], "The transformed shape is incorrect!")
//        XCTAssertEqual(shape.localVertices[1] + Vector2.unit, transformed[1], "The transformed shape is incorrect!")
//        XCTAssertEqual(shape.localVertices[2] + Vector2.unit, transformed[2], "The transformed shape is incorrect!")
//        XCTAssertEqual(shape.localVertices[3] + Vector2.unit, transformed[3], "The transformed shape is incorrect!")
    }
    
    func testOffsetTransformVertices()
    {
        // Create a small box shape
        var shape = ClosedShape()
        
        shape.begin()
        shape.addVertex(Vector2(0, 0))
        shape.addVertex(Vector2(1, 0))
        shape.addVertex(Vector2.unit)
        shape.addVertex(Vector2(0, 1))
        shape.finish(recentering: true)
        
        // Create the transformed shape with no modifications
        var transformed = shape.transformedBy(translatingBy: Vector2.unit, rotatingBy: 0, scalingBy: Vector2.unit)
        
        // Assert that both shapes are equal
        XCTAssertEqual(shape.localVertices[0] + Vector2.unit, transformed[0], "The transformed shape is incorrect!")
        XCTAssertEqual(shape.localVertices[1] + Vector2.unit, transformed[1], "The transformed shape is incorrect!")
        XCTAssertEqual(shape.localVertices[2] + Vector2.unit, transformed[2], "The transformed shape is incorrect!")
        XCTAssertEqual(shape.localVertices[3] + Vector2.unit, transformed[3], "The transformed shape is incorrect!")
    }
    
    func testRotateTransformVertices()
    {
        // Create a small box shape
        var shape = ClosedShape()
        
        shape.begin()
        shape.addVertex(Vector2(0, 0))
        shape.addVertex(Vector2(1, 0))
        shape.addVertex(Vector2.unit)
        shape.addVertex(Vector2(0, 1))
        shape.finish(recentering: true)
        
        // Create the transformed shape with no modifications
        //var transformed = shape.transformVertices(Vector2.unit, angleInRadians: PI, localScale: Vector2.unit)
        
        // Assert that both shapes are equal
        //for i in 0..<shape.localVertices.count
        //{
            //XCTAssertEqual(shape.localVertices[i], transformed[i], "The transformed shape is incorrect!")
        //}
    }
}
