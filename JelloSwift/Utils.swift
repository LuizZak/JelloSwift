//
//  Utils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 03/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import Foundation

public func +=<T>(inout lhs:Array<T>, rhs:T)
{
    lhs.append(rhs)
}

public func -=<T: Equatable>(inout lhs:Array<T>, rhs:T)
{
    lhs.remove(rhs)
}

extension Array
{
    mutating func remove<T: Equatable>(object : T)
    {
        for i in 0..<self.count
        {
            guard let item = self[i] as? T else {
                continue
            }
            
            if(item == object)
            {
                self.removeAtIndex(i)
                
                return
            }
        }
    }
}

extension SequenceType
{
    func forEach(@noescape doThis: (element: Self.Generator.Element) -> Void)
    {
        for e in self
        {
            doThis(element: e)
        }
    }
    
    func forEach(@noescape doThis: (index: Int, element: Self.Generator.Element) -> Void)
    {
        for e in self.enumerate()
        {
            doThis(e)
        }
    }
    
    func first(compute: Self.Generator.Element -> Bool) -> Self.Generator.Element?
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
    
    func last(compute: Self.Generator.Element -> Bool) -> Self.Generator.Element?
    {
        var last: Self.Generator.Element?
        for item in self
        {
            if(compute(item))
            {
                last = item
            }
        }
        
        return last
    }
    
    func any(compute: Self.Generator.Element -> Bool) -> Bool
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

public func fillArray<T>(object: T, count: Int) -> [T]
{
    return [T](count: count, repeatedValue: object)
}