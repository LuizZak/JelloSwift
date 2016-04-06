//
//  Utils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 03/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

enum SequenceError: ErrorType
{
    case ElementNotFound
}

public func +=<T, U: RangeReplaceableCollectionType where U.Generator.Element == T>(inout lhs: U, rhs: T)
{
    lhs.append(rhs)
}

public func -=<T: Equatable, U: RangeReplaceableCollectionType where U.Generator.Element == T>(inout lhs: U, rhs: T)
{
    lhs.remove(rhs)
}

extension SequenceType
{
    typealias T = Self.Generator.Element
    
    /// Runs a block statement for every item on this sequence
    func forEach(@noescape doThis: () -> ())
    {
        for _ in self
        {
            doThis()
        }
    }
    
    // MARK: Helper collection searching methods
    
    /// Returns the first item in the sequence that when passed through `compute` returns true.
    /// Returns nil if no item was found
    func firstOrDefault(compute: T -> Bool) -> T?
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
    
    /// Returns the last item in the sequence that when passed through `compute` returns true.
    /// Returns nil if no item was found
    func lastOrDefault(compute: T -> Bool) -> T?
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
    
    /// Returns the first item in the sequence that when passed through `compute` returns true.
    /// Throws a `SequenceError.ElementNotFound` error if no element is found
    func first(compute: T -> Bool) throws -> T
    {
        if let first = firstOrDefault(compute) {
            return first
        }
        
        throw SequenceError.ElementNotFound
    }
    
    /// Returns the last item in the sequence that when passed through `compute` returns true.
    /// Throws a `SequenceError.ElementNotFound` error if no element is found
    func last(compute: T -> Bool) throws -> T
    {
        if let last = lastOrDefault(compute) {
            return last
        }
        
        throw SequenceError.ElementNotFound
    }
    
    // MARK: Helper collection checking methods
    
    /// Returns true if any of the elements in this sequence return true when passed through `compute`.
    /// Succeeds fast on the first item that returns true
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
    
    /// Returns true if all of the elements in this sequence return true when passed through `compute`.
    /// Fails fast on the first item that returns false
    func all(compute: T -> Bool) -> Bool
    {
        for item in self
        {
            if(!compute(item))
            {
                return false
            }
        }
        
        return true
    }
}

extension RangeReplaceableCollectionType where Generator.Element: Equatable
{
    /// Removes a given element from this collection, using the element's equality check to determine the first match to remove
    mutating func remove(object: Self.Generator.Element)
    {
        for i in self.startIndex..<self.endIndex
        {
            if (self[i] == object)
            {
                self.removeAtIndex(i)
                
                return
            }
        }
    }
}

extension RangeReplaceableCollectionType
{
    /// Removes a given element from this collection, using the provided equality check to determine deletion matches
    mutating func remove(object: Self.Generator.Element, @noescape compare: Self.Generator.Element throws -> Bool) rethrows
    {
        for i in self.startIndex..<self.endIndex
        {
            if (try compare(self[i]))
            {
                self.removeAtIndex(i)
                
                return
            }
        }
    }
}

extension UIColor {
    func flattenWithColor(foreColor: UIColor) -> UIColor {
        return flattenColors(self, withColor: foreColor)
    }
    
    func toRGBA() -> Int32 {
        func denormalize(value: CGFloat) -> Int32 {
            return Int32(max(0, min(255, value * 255)))
        }
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let ret: Int32 = (denormalize(alpha) << 24) | (denormalize(red) << 16) | (denormalize(green) << 8) | (denormalize(blue))
        
        return ret
    }
    
    static func fromARGB(argb: Int32) -> UIColor {
        let blue = argb & 0xff;
        let green = argb >> 8 & 0xff;
        let red = argb >> 16 & 0xff;
        let alpha = argb >> 24 & 0xff;
        
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha) / 255.0)
    }
}

func flattenColors(backColor: UIColor, withColor foreColor: UIColor) -> UIColor {
    // Based off an answer by an anonymous user on StackOverlow http://stackoverflow.com/questions/1718825/blend-formula-for-gdi/2223241#2223241
    var backR: CGFloat = 0, backG: CGFloat = 0, backB: CGFloat = 0, backA: CGFloat = 0
    
    var foreR: CGFloat = 0, foreG: CGFloat = 0, foreB: CGFloat = 0, foreA: CGFloat = 0
    
    backColor.getRed(&backR, green: &backG, blue: &backB, alpha: &backA)
    foreColor.getRed(&foreR, green: &foreG, blue: &foreB, alpha: &foreA)
    
    if (foreA == 0) {
        return backColor
    }
    if (foreA == 1) {
        return foreColor
    }
    
    let backAlphaFloat = backA
    let foreAlphaFloat = foreA
    
    let foreAlphaNormalized = foreAlphaFloat
    let backColorMultiplier = backAlphaFloat * (1 - foreAlphaNormalized)
    
    let alpha = backAlphaFloat + foreAlphaFloat - backAlphaFloat * foreAlphaNormalized
    
    return UIColor(red: min(1, (foreR * foreAlphaFloat + backR * backColorMultiplier) / alpha), green: min(1, (foreG * foreAlphaFloat + backG * backColorMultiplier) / alpha), blue: min(1, (foreB * foreAlphaFloat + backB * backColorMultiplier) / alpha), alpha: alpha)
    
}
