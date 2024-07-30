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

    // Precision delta

    #if arch(x86_64) || arch(arm64)
        let delta: JFloat = 1e-14
    #else
        let delta: JFloat = 1e-6
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

        XCTAssertEqual(transformed.x, expected.x, accuracy: delta)
        XCTAssertEqual(transformed.y, expected.y, accuracy: delta)
    }

    func testCompoundMatrix() {
        // Tests a Vector2.matrix() to apply translation, scaling and rotation
        // of a Vector2
        // Order of operations should be: scaling -> rotating -> translating

        let vector = Vector2(x: 10, y: 10)
        let expected = Vector2(x: 5, y: 15)

        let matrix = Vector2.matrix(
            scalingBy: Vector2(x: 0.5, y: 0.5),
            rotatingBy: JFloat.pi / 2,
            translatingBy: Vector2(x: 10, y: 10)
        )

        let transformed = vector * matrix

        XCTAssertEqual(transformed.x, expected.x, accuracy: delta)
        XCTAssertEqual(transformed.y, expected.y, accuracy: delta)
    }

    func testMin() {
        let vec1 = Vector2(x: 1, y: -1)
        let vec2 = Vector2(x: 0, y: 2)

        XCTAssertEqual(min(vec1, vec2), Vector2(x: 0, y: -1))
    }

    func testMax() {
        let vec1 = Vector2(x: 1, y: -1)
        let vec2 = Vector2(x: 0, y: 2)

        XCTAssertEqual(max(vec1, vec2), Vector2(x: 1, y: 2))
    }

    func testAverageVectorPerformance() {
        let input: [Vector2] = (1...1000000).map { Vector2(x: $0, y: $0) }

        measure {
            _=input.averageVector()
        }
    }
}
