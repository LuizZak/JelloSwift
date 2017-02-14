//
//  Utils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 03/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import Foundation

public func clamp<T: Comparable>(_ value: T, minimum: T, maximum: T) -> T {
    return value < minimum ? minimum
        : value > maximum ? maximum : value
}

extension Comparable {
    func clamped(minimum: Self, maximum: Self) -> Self {
        return clamp(self, minimum: minimum, maximum: maximum)
    }
}

extension Sequence {
    typealias Element = Self.Iterator.Element
    
    // MARK: Helper collection searching methods
    
    /// Returns the last item in the sequence that when passed through `compute` returns true.
    /// Returns nil if no item was found
    func last(where compute: (Element) -> Bool) -> Element? {
        var last: Element?
        for item in self {
            if(compute(item)) {
                last = item
            }
        }
        
        return last
    }
    
    // MARK: Helper collection checking methods
    
    /// Returns true if any of the elements in this sequence return true when passed through `compute`.
    /// Succeeds fast on the first item that returns true
    func any(where compute: (Element) -> Bool) -> Bool {
        for item in self {
            if(compute(item)) {
                return true
            }
        }
        
        return false
    }
    
    /// Returns true if all of the elements in this sequence return true when passed through `compute`.
    /// Fails fast on the first item that returns false
    func all(where compute: (Element) -> Bool) -> Bool {
        for item in self {
            if(!compute(item)) {
                return false
            }
        }
        
        return true
    }
}

extension RangeReplaceableCollection where Iterator.Element: Equatable {
    /// Removes a given element from this collection, using the element's equality check to determine the first match to remove
    mutating func remove(_ object: Self.Iterator.Element) {
        var index = startIndex
        
        while(index != endIndex) {
            index = self.index(after: index)
            
            if(self[index] == object) {
                remove(at: index)
                return
            }
        }
    }
}

extension RangeReplaceableCollection {
    /// Removes the first element that fulfills a given condition closure
    mutating func remove(compare: (Self.Iterator.Element) throws -> Bool) rethrows {
        var index = startIndex
        
        while(index != endIndex) {
            index = self.index(after: index)
            
            if(try compare(self[index])) {
                remove(at: index)
                return
            }
        }
    }
}
