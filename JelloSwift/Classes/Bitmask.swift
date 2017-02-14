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
    @discardableResult
    public mutating func setBitOn(atIndex index: Int) -> UInt {
        self |= 1 << UInt(index > 0 ? index - 1 : 0)
        return self
    }
    
    @discardableResult
    public mutating func setBitOff(atIndex index: Int) -> UInt {
        self &= ~(1 << UInt(index > 0 ? index - 1 : 0))
        return self
    }
}
