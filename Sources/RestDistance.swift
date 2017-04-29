//
//  RestDistance.swift
//  Pods
//
//  Created by Luiz Fernando Silva on 28/04/17.
//
//

/// Specifies a rest distance for a body joint or sprint.
/// Distances can either by fixed by a distance, or ranged so the relevant forces
/// only applies within a specified range
public enum RestDistance: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    
    /// Fixed distance
    case fixed(JFloat)
    
    /// Distance is ranged between a minimum and maximum value
    case ranged(min: JFloat, max: JFloat)
    
    /// Returns the minimum distance for this rest distance.
    /// If the current value is .fixed, this method always returns the rest
    /// distance it represents, if .ranged, it returns its min value
    public var minimumDistance: JFloat {
        switch(self) {
        case .fixed(let value),
             .ranged(let value, _):
            return value
        }
    }
    
    /// Returns the maximum distance for this rest distance.
    /// If the current value is .fixed, this method always returns the rest
    /// distance it represents, if .ranged, it returns its max value
    public var maximumDistance: JFloat {
        switch(self) {
        case .fixed(let value),
             .ranged(_, let value):
            return value
        }
    }
    
    public init(integerLiteral value: Int) {
        self = .fixed(JFloat(value))
    }
    
    public init(floatLiteral value: Double) {
        self = .fixed(JFloat(value))
    }
    
    /// Returns whether a given range is within the range of this rest
    /// distance.
    /// If the current value is .fixed, this does an exact equality
    /// operation, if .ranged, it performs `value > min && value < max`
    public func inRange(value: JFloat) -> Bool {
        switch(self) {
        case .fixed(let d):
            return value == d
        case .ranged(let min, let max):
            return value > min && value < max
        }
    }
    
    /// Clamps a given value to be within the range of this rest distance.
    /// If the current value is .fixed, this method always returns the rest
    /// distance it represents, if .ranged, it performs
    /// `max(minValue, min(maxValue, value))`
    public func clamp(value: JFloat) -> JFloat {
        switch(self) {
        case .fixed(let d):
            return d
        case .ranged(let min, let max):
            return Swift.max(min, Swift.min(max, value))
        }
    }
}

/// Helper operator for creating a rest distance
@available(*, deprecated, message: "use <-> instead")
public func ...(lhs: JFloat, rhs: JFloat) -> RestDistance {
    return .ranged(min: lhs, max: rhs)
}

/// An operator for forming ranged rest distances with
infix operator <-> : RangeFormationPrecedence

/// Helper operator for creating a rest distance
public func <->(lhs: JFloat, rhs: JFloat) -> RestDistance {
    return .ranged(min: lhs, max: rhs)
}
