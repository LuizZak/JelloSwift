//
//  Bitmask.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

public typealias Bitmask = UInt

infix operator +& : AdditionPrecedence
infix operator -& : AdditionPrecedence

@discardableResult
public func +&(lhs: inout Bitmask, rhs: Int) -> Bitmask
{
    lhs |= 1 << UInt(rhs > 0 ? rhs - 1 : 0)
    return lhs
}

@discardableResult
public func -&(lhs: inout Bitmask, rhs: Int) -> Bitmask
{
    lhs &= ~(1 << UInt(rhs > 0 ? rhs - 1 : 0))
    return lhs
}
