//
//  WorldTests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 25/05/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import JelloSwift

class WorldTests: XCTestCase {
    
    // MARK: Bitmask tests
    
    func testBitmaskSetRange() {
        AssertBitmasksMatch(Bitmask(withOneBitsFromOffset: 0, count: 64), ~Bitmask.allZeros)
        AssertBitmasksMatch(Bitmask(withOneBitsFromOffset: 1, count: 1), 0b01)
        AssertBitmasksMatch(Bitmask(withOneBitsFromOffset: 1, count: 2), 0b11)
        AssertBitmasksMatch(Bitmask(withOneBitsFromOffset: 10, count: 2), 0b00000110_00000000)
    }
    
    // MARK: Collision bitmask generation testing
    
    func testGenerateBitmaskMinimum() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: world.worldLimits.minimum, max: world.worldLimits.minimum)
        let bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, 1)
        AssertBitmasksMatch(bitmasks.bitmaskY, 1)
    }
    
    func testGenerateBitmaskMaximum() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: world.worldLimits.maximum, max: world.worldLimits.maximum)
        let bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, 1 << 63)
        AssertBitmasksMatch(bitmasks.bitmaskY, 1 << 63)
    }
    
    func testGenerateBitmaskCenter() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: .zero, max: .zero)
        let bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, 1 << 31) // Approximately half-way
        AssertBitmasksMatch(bitmasks.bitmaskY, 1 << 31)
    }
    
    func testGenerateBitmaskFilling() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: world.worldLimits.minimum, max: world.worldLimits.maximum)
        let bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, ~UInt.allZeros)
        AssertBitmasksMatch(bitmasks.bitmaskY, ~UInt.allZeros)
    }
    
    func testGenerateBitmaskQuarter() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: .zero, max: world.worldLimits.maximum)
        let bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, 0b11111111_11111111_11111111_11111111_10000000_00000000_00000000_00000000)
        AssertBitmasksMatch(bitmasks.bitmaskY, 0b11111111_11111111_11111111_11111111_10000000_00000000_00000000_00000000)
    }
    
    func testGenerateBitmaskSmallRect() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: Vector2(value: -4), max: Vector2(value: 0))
        let bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, 0x0000_0000_FF00_0000)
        AssertBitmasksMatch(bitmasks.bitmaskY, 0x0000_0000_FF00_0000)
    }
    
    func testGenerateBitmaskLimitBounds() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        // Test maximum limits
        var aabb = AABB(min: Vector2(value: 30), max: Vector2(value: 32))
        var bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, 0x8000_0000_0000_0000)
        AssertBitmasksMatch(bitmasks.bitmaskY, 0x8000_0000_0000_0000)
        
        // Test minimum limits
        aabb = AABB(min: Vector2(value: -33), max: Vector2(value: -32))
        bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, 0x0000_0000_0000_0001)
        AssertBitmasksMatch(bitmasks.bitmaskY, 0x0000_0000_0000_0001)
    }
    
    func testGenerateBitmaskNaN() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: Vector2(x: JFloat.nan, y: 0), max: Vector2(value: 0))
        let bitmasks = world.bitmask(for: aabb)
        
        XCTAssertEqual(bitmasks.bitmaskX, 0)
        XCTAssertEqual(bitmasks.bitmaskY, 0)
    }
    
    fileprivate func AssertBitmasksMatch(_ actual: Bitmask, _ expected: Bitmask, file: String = #file, line: UInt = #line) {
        if actual != expected {
            let message = "Bitmasks do not match, expected:\n\(formatBinary(expected))\nfound:\n\(formatBinary(actual))"
            
            recordFailure(withDescription: message, inFile: file, atLine: line, expected: false)
        }
    }
}

fileprivate func formatBinary(_ value: Bitmask) -> String {
    let base = String(value, radix: 2)
    let lengthInBits = MemoryLayout<Bitmask>.size * 8
    
    let pad = String(repeating: "0", count: lengthInBits - base.characters.count)
    let resultPreSpace = pad + base
    
    // Inject separators every 8 bits
    var result: String = ""
    for bit in stride(from: 0, to: 64, by: 8) {
        let sliceStart = resultPreSpace.index(resultPreSpace.startIndex, offsetBy: bit)
        let sliceEnd = resultPreSpace.index(sliceStart, offsetBy: 8)
        
        result += resultPreSpace[sliceStart..<sliceEnd] + " "
    }
    
    return "0b" + result.trimmingCharacters(in: .whitespaces)
}
