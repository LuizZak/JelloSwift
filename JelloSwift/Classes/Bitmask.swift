//
//  Bitmask.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import Foundation

public typealias Bitmask = UInt

extension Bitmask {
    
    /// Sets the nth bit at `index` to on (1)
    @discardableResult
    public mutating func setBitOn(atIndex index: Int) -> UInt {
        self |= 1 << UInt(index > 0 ? index - 1 : 0)
        return self
    }
    
    /// Sets the nth bit at `index` to off (0)
    @discardableResult
    public mutating func setBitOff(atIndex index: Int) -> UInt {
        self &= ~(1 << UInt(index > 0 ? index - 1 : 0))
        return self
    }
}
