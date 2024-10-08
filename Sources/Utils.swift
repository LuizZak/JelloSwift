//
//  Utils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 03/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Clamps a value so it's always `>= minimum` and `<= maximum`
public func clamp<T: Comparable>(_ value: T, minimum: T, maximum: T) -> T {
    return value < minimum ? minimum
        : value > maximum ? maximum : value
}

extension Comparable {

    /// Clamps a value so it's always `>= minimum` and `<= maximum`
    func clamped(minimum: Self, maximum: Self) -> Self {
        return clamp(self, minimum: minimum, maximum: maximum)
    }
}

extension Sequence {

    // MARK: Helper collection searching methods

    /// Returns the last item in the sequence that when passed through `compute`
    /// returns true.
    /// Returns nil if no item was found
    func last(where compute: (Iterator.Element) -> Bool) -> Iterator.Element? {
        var last: Iterator.Element?
        for item in self {
            if compute(item) {
                last = item
            }
        }

        return last
    }

    // MARK: Helper collection checking methods

    /// Returns true if any of the elements in this sequence return true when
    /// passed through `compute`.
    /// Succeeds fast on the first item that returns true
    func any(where compute: (Iterator.Element) -> Bool) -> Bool {
        for item in self {
            if compute(item) {
                return true
            }
        }

        return false
    }

    /// Returns true if all of the elements in this sequence return true when
    /// passed through `compute`.
    /// Fails fast on the first item that returns false
    func all(where compute: (Iterator.Element) -> Bool) -> Bool {
        for item in self {
            if !compute(item) {
                return false
            }
        }

        return true
    }
}

extension RangeReplaceableCollection where Iterator.Element: Equatable {
    /// Removes a given element from this collection, using the element's
    /// equality check to determine the first match to remove
    mutating func remove(_ object: Iterator.Element) {
        guard !isEmpty else { return }

        var index = startIndex

        while index != endIndex {
            defer { index = self.index(after: index) }

            if self[index] == object {
                remove(at: index)
                return
            }
        }
    }
}

extension RangeReplaceableCollection {
    /// Removes the first element that fulfills a given condition closure
    mutating func remove(where compute: (Iterator.Element) throws -> Bool) rethrows {
        guard !isEmpty else { return }

        var index = startIndex

        while index != endIndex {
            defer { index = self.index(after: index) }

            if try compute(self[index]) {
                remove(at: index)
                return
            }
        }
    }
}
