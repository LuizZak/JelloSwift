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
        AssertBitmasksMatch(Bitmask(withOneBitsFromOffset: 0, count: Int(bitmaskBitSize)), ~0)
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
        
        AssertBitmasksMatch(bitmasks.bitmaskX, Bitmask(1 << (bitmaskBitSize - 1)))
        AssertBitmasksMatch(bitmasks.bitmaskY, Bitmask(1 << (bitmaskBitSize - 1)))
    }
    
    func testGenerateBitmaskCenter() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: .zero, max: .zero)
        let bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, 1 << (bitmaskBitSize / 2 - 1)) // Approximately half-way
        AssertBitmasksMatch(bitmasks.bitmaskY, 1 << (bitmaskBitSize / 2 - 1))
    }
    
    func testGenerateBitmaskFilling() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: world.worldLimits.minimum, max: world.worldLimits.maximum)
        let bitmasks = world.bitmask(for: aabb)
        
        AssertBitmasksMatch(bitmasks.bitmaskX, ~0)
        AssertBitmasksMatch(bitmasks.bitmaskY, ~0)
    }
    
    func testGenerateBitmaskQuarter() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        let aabb = AABB(min: .zero, max: world.worldLimits.maximum)
        let bitmasks = world.bitmask(for: aabb)
        
        #if arch(x86_64) || arch(arm64)
            AssertBitmasksMatch(bitmasks.bitmaskX, 0b11111111_11111111_11111111_11111111_10000000_00000000_00000000_00000000)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0b11111111_11111111_11111111_11111111_10000000_00000000_00000000_00000000)
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
            AssertBitmasksMatch(bitmasks.bitmaskX, 0x0000_0000_FF00_0000)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0x0000_0000_FF00_0000)
        #else
            AssertBitmasksMatch(bitmasks.bitmaskX, 0x0000_F800)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0x0000_F800)
        #endif
    }
    
    func testGenerateBitmaskLimitBounds() {
        let world = World()
        world.setWorldLimits(-Vector2(value: 20), Vector2(value: 20))
        
        // Test maximum limits
        var aabb = AABB(min: Vector2(value: 30), max: Vector2(value: 32))
        var bitmasks = world.bitmask(for: aabb)

        #if arch(x86_64) || arch(arm64)
            AssertBitmasksMatch(bitmasks.bitmaskX, 0x8000_0000_0000_0000)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0x8000_0000_0000_0000)
        #else
            AssertBitmasksMatch(bitmasks.bitmaskX, 0x8000_0000)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0x8000_0000)
        #endif
        
        // Test minimum limits
        aabb = AABB(min: Vector2(value: -33), max: Vector2(value: -32))
        bitmasks = world.bitmask(for: aabb)
        
        #if arch(x86_64) || arch(arm64)
            AssertBitmasksMatch(bitmasks.bitmaskX, 0x0000_0000_0000_0001)
            AssertBitmasksMatch(bitmasks.bitmaskY, 0x0000_0000_0000_0001)
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
    
    fileprivate func AssertBitmasksMatch(_ actual: Bitmask, _ expected: Bitmask, file: String = #file, line: Int = #line) {
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
    for bit in stride(from: 0, to: lengthInBits, by: 8) {
        let sliceStart = resultPreSpace.index(resultPreSpace.startIndex, offsetBy: bit)
        let sliceEnd = resultPreSpace.index(sliceStart, offsetBy: 8)
        
        result += resultPreSpace[sliceStart..<sliceEnd] + " "
    }
    
    return "0b" + result.trimmingCharacters(in: .whitespaces)
}
