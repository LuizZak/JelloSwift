//
//  WorldTests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 25/05/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import JelloSwift

let bitmaskBitSize = Bitmask(MemoryLayout<Bitmask>.size * 8)

class WorldTests: XCTestCase {

    // MARK: Bitmask tests

    func testBitmaskSetRange() {
        assertBitmasksMatch(Bitmask(withOneBitsFromOffset: 0, count: Int(bitmaskBitSize)), ~0)
        assertBitmasksMatch(Bitmask(withOneBitsFromOffset: 1, count: 1), 0b01)
        assertBitmasksMatch(Bitmask(withOneBitsFromOffset: 1, count: 2), 0b11)
        assertBitmasksMatch(Bitmask(withOneBitsFromOffset: 10, count: 2), 0b00000110_00000000)
    }

    // MARK: Collision bitmask generation testing

    func testGenerateBitmaskMinimum() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let aabb = AABB(min: world.worldLimits.minimum, max: world.worldLimits.minimum)
        let bitmasks = world.bitmask(for: aabb)

        assertBitmasksMatch(bitmasks.bitmaskX, 1)
        assertBitmasksMatch(bitmasks.bitmaskY, 1)
    }

    func testGenerateBitmaskMaximum() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let aabb = AABB(min: world.worldLimits.maximum, max: world.worldLimits.maximum)
        let bitmasks = world.bitmask(for: aabb)

        assertBitmasksMatch(bitmasks.bitmaskX, Bitmask(1 &<< (bitmaskBitSize - 1)))
        assertBitmasksMatch(bitmasks.bitmaskY, Bitmask(1 &<< (bitmaskBitSize - 1)))
    }

    func testGenerateBitmaskCenter() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let aabb = AABB(min: .zero, max: .zero)
        let bitmasks = world.bitmask(for: aabb)

        assertBitmasksMatch(bitmasks.bitmaskX, 1 &<< (bitmaskBitSize / 2 - 1)) // Approximately half-way
        assertBitmasksMatch(bitmasks.bitmaskY, 1 &<< (bitmaskBitSize / 2 - 1))
    }

    func testGenerateBitmaskFilling() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let aabb = AABB(min: world.worldLimits.minimum, max: world.worldLimits.maximum)
        let bitmasks = world.bitmask(for: aabb)

        assertBitmasksMatch(bitmasks.bitmaskX, ~0)
        assertBitmasksMatch(bitmasks.bitmaskY, ~0)
    }

    func testGenerateBitmaskQuarter() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let aabb = AABB(min: .zero, max: world.worldLimits.maximum)
        let bitmasks = world.bitmask(for: aabb)

        #if arch(x86_64) || arch(arm64)
            assertBitmasksMatch(bitmasks.bitmaskX, 0b11111111_11111111_11111111_11111111_10000000_00000000_00000000_00000000)
            assertBitmasksMatch(bitmasks.bitmaskY, 0b11111111_11111111_11111111_11111111_10000000_00000000_00000000_00000000)
        #else
            AssertBitmasksMatch(bitmasks.bitmaskX, 0b11111111_11111111_10000000_00000000)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0b11111111_11111111_10000000_00000000)
        #endif
    }

    func testGenerateBitmaskSmallRect() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let aabb = AABB(min: Vector2(value: -4), max: Vector2(value: 0))
        let bitmasks = world.bitmask(for: aabb)

        #if arch(x86_64) || arch(arm64)
            assertBitmasksMatch(bitmasks.bitmaskX, 0x0000_0000_FF00_0000)
            assertBitmasksMatch(bitmasks.bitmaskY, 0x0000_0000_FF00_0000)
        #else
            AssertBitmasksMatch(bitmasks.bitmaskX, 0x0000_F800)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0x0000_F800)
        #endif
    }

    func testGenerateBitmaskEmptyRectRect() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let aabb = AABB(min: Vector2(value: 0), max: Vector2(value: 0))
        let bitmasks = world.bitmask(for: aabb)

        #if arch(x86_64) || arch(arm64)
            assertBitmasksMatch(bitmasks.bitmaskX, 0x0000_0000_8000_0000)
            assertBitmasksMatch(bitmasks.bitmaskY, 0x0000_0000_8000_0000)
        #else
            AssertBitmasksMatch(bitmasks.bitmaskX, 0x0000_8800)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0x0000_8800)
        #endif
    }

    func testGenerateBitmaskLimitBounds() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        // Test maximum limits
        var aabb = AABB(min: Vector2(value: 30), max: Vector2(value: 32))
        var bitmasks = world.bitmask(for: aabb)

        #if arch(x86_64) || arch(arm64)
            assertBitmasksMatch(bitmasks.bitmaskX, 0x8000_0000_0000_0000)
            assertBitmasksMatch(bitmasks.bitmaskY, 0x8000_0000_0000_0000)
        #else
            AssertBitmasksMatch(bitmasks.bitmaskX, 0x8000_0000)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0x8000_0000)
        #endif

        // Test minimum limits
        aabb = AABB(min: Vector2(value: -33), max: Vector2(value: -32))
        bitmasks = world.bitmask(for: aabb)

        #if arch(x86_64) || arch(arm64)
            assertBitmasksMatch(bitmasks.bitmaskX, 0x0000_0000_0000_0001)
            assertBitmasksMatch(bitmasks.bitmaskY, 0x0000_0000_0000_0001)
        #else
            AssertBitmasksMatch(bitmasks.bitmaskX, 0x0000_0001)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0x0000_0001)
        #endif
    }

    func testGenerateBitmaskNaN() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let aabb = AABB(min: Vector2(x: JFloat.nan, y: 0), max: Vector2(value: 0))
        let bitmasks = world.bitmask(for: aabb)

        XCTAssertEqual(bitmasks.bitmaskX, 0)
        XCTAssertEqual(bitmasks.bitmaskY, 0)
    }

    func testBitmasksIntersect() {
        let world = World()

        let bit1: (Bitmask, Bitmask) = (0b1111_0000, 0b0000_1111)
        let bit2: (Bitmask, Bitmask) = (0b0000_1111, 0b1111_0000)
        let bit3: (Bitmask, Bitmask) = (0b0001_1110, 0b0111_1000)

        XCTAssertTrue(world.bitmasksIntersect(bit1, bit1))
        XCTAssertFalse(world.bitmasksIntersect(bit1, bit2))
        XCTAssertTrue(world.bitmasksIntersect(bit1, bit3))
        XCTAssertTrue(world.bitmasksIntersect(bit2, bit3))
    }

    func testRayCast() {
        // Tests raycasting in world. World looks roughly like this:
        //
        // (0, 0) ___
        //       |   |  _____
        //       |___| |     |
        //             |_____|
        //

        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let shape1 = ClosedShape.square(ofSide: 6)
        let shape2 = ClosedShape.rectangle(ofSides: Vector2(x: 8, y: 6))

        let body1 = Body(world: world, shape: shape1, position: Vector2(value: 3))
        _=Body(world: world, shape: shape2, position: Vector2(x: 10, y: 6))

        guard let (pt, body) = world.rayCast(from: Vector2(x: -10, y: -10), to: Vector2(x: 10, y: 10)) else {
            XCTFail("Should have found body")
            return
        }

        XCTAssertEqual(body1, body)
        XCTAssertEqual(.zero, pt)
    }

    func testRayCast2() {
        // Tests another raycasting scenario, w/ a circle this time

        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))

        let shape = ClosedShape.circle(ofRadius: 6, pointCount: 10)

        let body = Body(world: world, shape: shape, position: Vector2(x: 2, y: 10))

        guard let (_, bd) = world.rayCast(from: Vector2(x: 0, y: -10), to: Vector2(x: 4, y: 20)) else {
            XCTFail("Should have found body")
            return
        }

        XCTAssertEqual(body, bd)
    }

    func testCollisionSolveSquares() {
        // Test simple collision detection between two overlapping square-shaped
        // bodies
        //
        // Simulation looks roughly like this:
        //   ______
        //  |      | ⟋  ⟍
        //  |      <       > (that's supposed to be two squares, with the right
        //  |______| ⟍  ⟋    one twisted 45° counter-clockwise.)
        //

        let world = World()
        let observer = CollisionObserver()
        world.collisionObserver = observer

        let shape = ClosedShape.square(ofSide: 10)

        let bodyA = Body(shape: shape, position: Vector2(x: 0, y: 0))
        let bodyB = Body(shape: shape, position: Vector2(x: 11, y: 0), angle: JFloat.pi / 4)

        world.addBody(bodyA)
        world.addBody(bodyB)

        world.update(1.0 / 200.0)

        // Verify collision was reported
        XCTAssertEqual(observer.collisions.count, 1)
    }

    fileprivate func assertBitmasksMatch(_ actual: Bitmask,
                                         _ expected: Bitmask,
                                         file: StaticString = #file,
                                         line: UInt = #line) {

        if actual != expected {
            let message = "Bitmasks do not match, expected:\n\(formatBinary(expected))\nfound:\n\(formatBinary(actual))"

            XCTFail(message, file: file, line: line)
        }
    }

    class CollisionObserver: JelloSwift.CollisionObserver {
        var collisions: [BodyCollisionInformation] = []

        func bodiesDidCollide(_ infos: [BodyCollisionInformation]) {
            collisions = infos
        }

        func bodyCollision(_ info: BodyCollisionInformation, didExceedPenetrationThreshold penetrationThreshold: JFloat) {

        }
    }
}

fileprivate func formatBinary(_ value: Bitmask) -> String {
    let base = String(value, radix: 2)
    let lengthInBits = MemoryLayout<Bitmask>.size * 8

    let pad = String(repeating: "0", count: lengthInBits - base.count)
    let resultPreSpace = pad + base

    // Inject separators every 8 bits
    var result: String = ""
    for bit in stride(from: 0, to: lengthInBits, by: 8) {
        let sliceStart = resultPreSpace.index(resultPreSpace.startIndex, offsetBy: bit)
        let sliceEnd = resultPreSpace.index(sliceStart, offsetBy: 8)

        result += resultPreSpace[sliceStart..<sliceEnd] + " "
    }

    return "0b" + result.trimmingCharacters(in: .whitespaces)
}
