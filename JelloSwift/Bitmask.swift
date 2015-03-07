//
//  Bitmask.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

typealias Bitmask = UInt;

infix operator +& { associativity left precedence 140 }
infix operator -& { associativity left precedence 140 }

func +&(inout lhs: Bitmask, rhs: Int) -> Bitmask
{
    lhs |= 1 << UInt(rhs > 0 ? rhs - 1 : 0);
    return lhs;
}

func -&(inout lhs: Bitmask, rhs: Int) -> Bitmask
{
    lhs &= ~(1 << UInt(rhs > 0 ? rhs - 1 : 0));
    return lhs;
}