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
    func contains<T: Equatable>(object : T) -> Bool
    {
        for i in 0..<self.count
        {
            guard let item = self[i] as? T else {
                continue
            }
            
            if(item == object)
            {
                return true
            }
        }
        
        return false
    }
    
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
    
    func forEach(doThis: (element: T) -> Void)
    {
        for e in self
        {
            doThis(element: e)
        }
    }
}

public func fillArray<T: Equatable>(object: T, count: Int) -> [T]
{
    return [T](count: count, repeatedValue: object)
}