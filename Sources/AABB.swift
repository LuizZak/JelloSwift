//
//  AABB.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Represents an axis-aligned bounding box, utilized to figure out the AABB of
/// soft-bodies
public struct AABB {
    /// Returns an empty, invalid AABB
    static let empty = AABB()
    
    /// The validity of this AABB.
    /// AABBs that have a .invalid validity set cannot be used until they are
    /// expanded via calls to `AABB.expand(toInclude:)` methods bellow.
    public var validity = PointValidity.invalid
    
    /// Maximum points for this bounding box
    fileprivate(set) public var minimum = Vector2.zero
    
    /// Maximum point for this bounding box
    fileprivate(set) public var maximum = Vector2.zero
    
    /// Gets the X position of this AABB
    public var x: JFloat {
        return minimum.x
    }
    /// Gets the Y position of this AABB
    public var y: JFloat {
        return minimum.y
    }
    
    /// Gets the width of this AABB.
    /// This is the same as `maximum.x - minimum.x`
    public var width: JFloat {
        return maximum.x - minimum.x
    }
    
    /// Gets the height of this AABB
    /// This is the same as `maximum.y - minimum.y`
    public var height: JFloat {
        return maximum.y - minimum.y
    }
    
    /// Gets the middle X position of this AABB
    public var midX: JFloat {
        return (minimum.x + maximum.x) / 2
    }
    /// Gets the middle Y position of this AABB
    public var midY: JFloat {
        return (minimum.y + maximum.y) / 2
    }
    
    /// Initializes an empty, invalid AABB instance
    public init() {
        
    }
    
    /// Initializes a valid AABB instance out of the given minimum and maximum
    /// coordinates.
    /// The coordinates are not checked for ordering, and will be directly
    /// assigned to `minimum` and `maximum` properties.
    public init(min: Vector2, max: Vector2) {
        validity = .valid
      
        minimum = min
        maximum = max
    }
    
    /// Initializes a valid AABB out of a set of points, expanding to the
    /// smallest bounding box capable of fitting each point.
    public init(points: [Vector2]) {
        expand(toInclude: points)
    }
    
    /// Invalidates this AABB
    public mutating func clear() {
        validity = .invalid
    }
    
    /// Expands the bounding box of this AABB to include the given point. If the
    /// AABB is invalid, it sets the `minimum` and `maximum` coordinates to the
    /// point, if not, it fits the point, expanding the bounding box to fit the
    /// point, if necessary.
    public mutating func expand(toInclude point: Vector2) {
        if(validity == .invalid) {
            minimum = point
            maximum = point
            
            validity = .valid
        } else {
            minimum = min(minimum, point)
            maximum = max(maximum, point)
        }
    }
    
    /// Expands the bounding box of this AABB to include the given point set of
    /// points.
    /// Same as calling `expand(toInclude:Vector2)` over each point.
    /// If the array is empty, nothing is done.
    public mutating func expand(toInclude points: [Vector2]) {
        if(points.count == 0) {
            return
        }
        
        if(validity == .invalid) {
            minimum = points[0]
            maximum = points[0]
            
            validity = .valid
        }
        
        for p in points {
            minimum = min(minimum, p)
            maximum = max(maximum, p)
        }
    }
    
    /// Returns whether a given point is contained within this bounding box.
    /// The check is inclusive, so the edges of the bounding box are considered
    /// to contain the point as well.
    /// Returns false, if this AABB is invalid.
    public func contains(_ point: Vector2) -> Bool {
        if(validity == .invalid) {
            return false
        }
        
        return point >= minimum && point <= maximum
    }
    
    /// Returns whether this AABB completely contain another AABB inside it.
    public func contains(_ box: AABB) -> Bool {
        if(validity == .invalid || box.validity == .invalid) {
            return false
        }
        
        return box.minimum >= minimum && box.maximum <= maximum
    }
    
    /// Returns whether this AABB intersects the given AABB instance.
    /// This check is inclusive, so the edges of the bounding box are considered
    /// to intersect the other bounding box's edges as well.
    /// If either this, or the other bounding box are invalid, false is 
    /// returned.
    public func intersects(_ box: AABB) -> Bool {
        if(validity == .invalid || box.validity == .invalid) {
            return false
        }
        
        return minimum <= box.maximum && maximum >= box.minimum
    }
}

/// Specifies the point validity for a whole AABB.
/// AABBs of PointValidity.invalid type should not be considered
/// valid during checks of containment.
public enum PointValidity {
    case valid
    case invalid
}
