//
//  Vector2Tests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 17/02/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import JelloSwift

class Vector2Tests: XCTestCase {
    
    static var allTests = [
        ("testMatrixTranslate", testMatrixTranslate),
        ("testMatrixScale", testMatrixScale),
        ("testMatrixRotate", testMatrixRotate),
        ("testCompoundMatrix", testCompoundMatrix)
    ]
    
    // Precision delta
    
    #if arch(x86_64) || arch(arm64)
        let delta: JFloat = 0.00000000000001
    #else
        let delta: JFloat = 0.000001
    #endif
    
    func testMatrixTranslate() {
        // Tests a Vector2.matrix() to translate a Vector2
        
        let vector = Vector2(x: 10, y: 10)
        let expected = Vector2(x: -10, y: 20)
        
        let matrix = Vector2.matrix(translatingBy: Vector2(x: -20, y: 10))
        
        let transformed = vector * matrix
        
        XCTAssertEqual(expected, transformed)
    }
    
    func testMatrixScale() {
        // Tests a Vector2.matrix() to scale a Vector2
        
        let vector = Vector2(x: 10, y: -20)
        let expected = Vector2(x: 5, y: -40)
        
        let matrix = Vector2.matrix(scalingBy: Vector2(x: 0.5, y: 2))
        
        let transformed = vector * matrix
        
        XCTAssertEqual(expected, transformed)
    }
    
    func testMatrixRotate() {
        // Tests a Vector2.matrix() to rotate a Vector2
        
        let vector = Vector2(x: 10, y: 10)
        let expected = Vector2(x: -10, y: 10)
        
        let matrix = Vector2.matrix(rotatingBy: JFloat.pi / 2) // 90º
        
        let transformed = vector * matrix
        
        let diff = abs(expected - transformed)
        
        XCTAssert(diff.x <= delta)
        XCTAssert(diff.y <= delta)
    }
    
    func testCompoundMatrix() {
        // Tests a Vector2.matrix() to apply translation, scaling and rotation
        // of a Vector2
        // Order of operations should be: scaling -> rotating -> translating
        
        let vector = Vector2(x: 10, y: 10)
        let expected = Vector2(x: 5, y: 15)
        
        let matrix = Vector2.matrix(scalingBy: Vector2(x: 0.5, y: 0.5),
                                    rotatingBy: JFloat.pi / 2,
                                    translatingBy: Vector2(x: 10, y: 10))
        
        let transformed = vector * matrix
        
        let diff = abs(expected - transformed)
        
        XCTAssert(diff.x <= delta)
        XCTAssert(diff.y <= delta)
    }
}
