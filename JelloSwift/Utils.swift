//
//  Utils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 03/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import Foundation

public func +=<T>(inout lhs: Array<T>, rhs: T)
{
    lhs.append(rhs)
}

public func +=<T>(inout lhs: ContiguousArray<T>, rhs: T)
{
    lhs.append(rhs)
}

public func -=<T: Equatable>(inout lhs: Array<T>, rhs: T)
{
    lhs.remove(rhs)
}

public func -=<T: Equatable>(inout lhs: ContiguousArray<T>, rhs: T)
{
    lhs.remove(rhs)
}

extension Array where T: Equatable
{
    mutating func remove(object: T)
    {
        for (i, item) in self.enumerate()
        {
            if(item == object)
            {
                removeAtIndex(i)
                
                return
            }
        }
    }
}

extension ContiguousArray where T: Equatable
{
    mutating func remove(object: T)
    {
        for (i, item) in self.enumerate()
        {
            if(item == object)
            {
                removeAtIndex(i)
                
                return
            }
        }
    }
}

extension SequenceType
{
    typealias T = Self.Generator.Element
    
    func forEach(@noescape doThis: () -> ())
    {
        for _ in self
        {
            doThis()
        }
    }
    
    func forEach(@noescape doThis: (element: T) -> Void)
    {
        for e in self
        {
            doThis(element: e)
        }
    }
    
    func forEach(@noescape doThis: (index: Int, element: T) -> Void)
    {
        for e in enumerate()
        {
            doThis(e)
        }
    }
    
    func first(compute: T -> Bool) -> T?
    {
        for item in self
        {
            if(compute(item))
            {
                return item
            }
        }
        
        return nil
    }
    
    func last(compute: T -> Bool) -> T?
    {
        var last: T?
        for item in self
        {
            if(compute(item))
            {
                last = item
            }
        }
        
        return last
    }
    
    func any(compute: T -> Bool) -> Bool
    {
        for item in self
        {
            if(compute(item))
            {
                return true
            }
        }
        
        return false
    }
}