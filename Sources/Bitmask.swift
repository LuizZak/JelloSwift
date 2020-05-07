//
//  Bitmask.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

public typealias Bitmask = UInt

extension Bitmask {
    
    /// Initializes a new bitmask with a range of bits on (1).
    ///
    /// - Parameters:
    ///   - offset: 0-based offset, from the most significant bit (right-most),
    /// to start adding 1 bits to.
    ///   - count: Number of bits starting from `offset` to set to 1, including
    /// the bit at `offset` itself.
    @inlinable
    public init(withOneBitsFromOffset offset: Int, count: Int) {
        self = 0
        self.setBitsOn(offset: offset, count: count)
    }
    
    /// Sets a range of bits on on this bitmask.
    /// 
    /// Overwrites any previously set values.
    ///
    /// - Parameters:
    ///   - offset: 0-based offset, from the most significant bit (right-most),
    /// to start adding 1 bits to.
    ///   - count: Number of bits starting from `offset` to set to 1, including
    /// the bit at `offset` itself.
    @inlinable
    public mutating func setBitsOn(offset: Int, count: Int) {
        let mask = Bitmask(bitPattern: ~0) >> Bitmask(Bitmask.bitWidth - count)
        
        self = mask << Bitmask(offset > 0 ? offset - 1 : 0)
    }
    
    /// Sets the nth bit at `index` to on (1)
    @inlinable
    @discardableResult
    public mutating func setBitOn(atIndex index: Int) -> UInt {
        self |= 1 << Bitmask(index > 0 ? index - 1 : 0)
        return self
    }
    
    /// Sets the nth bit at `index` to off (0)
    @inlinable
    @discardableResult
    public mutating func setBitOff(atIndex index: Int) -> UInt {
        self &= ~(1 << Bitmask(index > 0 ? index - 1 : 0))
        return self
    }
}
