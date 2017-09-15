//
//  RestDistance.swift
//  Pods
//
//  Created by Luiz Fernando Silva on 28/04/17.
//
//

/// Specifies a rest distance for a body joint or sprint.
/// Distances can either be fixed by a distance, or ranged so forces only apply
/// when distance is outside a tolerance range.
public enum RestDistance: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    
    /// Fixed distance
    case fixed(JFloat)
    
    /// Distance is ranged between a minimum and maximum value
    case ranged(min: JFloat, max: JFloat)
    
    /// Returns the minimum distance for this rest distance.
    /// If the current value is .fixed, this method always returns the rest
    /// distance it represents, if .ranged, it returns its min value.
    ///
    /// Setting this value updates the `.fixed` value, or in case of `.ranged`
    /// it updates the minimum distance value.
    public var minimumDistance: JFloat {
        get {
            switch(self) {
            case .fixed(let value),
                 .ranged(let value, _):
                return value
            }
        }
        set {
            switch self {
            case .fixed:
                self = .fixed(newValue)
            case .ranged(_, let max):
                self = .ranged(min: newValue, max: max)
            }
        }
    }
    
    /// Returns the maximum distance for this rest distance.
    /// If the current value is .fixed, this method always returns the rest
    /// distance it represents, if .ranged, it returns its max value
    ///
    /// Setting this value updates the `.fixed` value, or in case of `.ranged`
    /// it updates the maximum distance value.
    public var maximumDistance: JFloat {
        get {
            switch(self) {
            case .fixed(let value),
                 .ranged(_, let value):
                return value
            }
        }
        set {
            switch self {
            case .fixed:
                self = .fixed(newValue)
            case .ranged(let min, _):
                self = .ranged(min: min, max: newValue)
            }
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

extension RestDistance: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        let caseNum = try container.decode(Int.self)
        
        switch caseNum {
        case 0:
            self = try .fixed(container.decode(JFloat.self))
        case 1:
            self = try .ranged(min: container.decode(JFloat.self), max: container.decode(JFloat.self))
        default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Unrecognized enum payload case '\(caseNum)'"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        switch self {
        case .fixed(let value):
            try container.encode(0)
            try container.encode(value)
        case let .ranged(min, max):
            try container.encode(1)
            try container.encode(min)
            try container.encode(max)
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
