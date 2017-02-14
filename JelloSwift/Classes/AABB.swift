//
//  AABB.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Represents an axis-aligned bounding box, utilized to figure out the AABB of soft-bodies
public struct AABB {
    /// Returns an empty, invalid AABB
    static let empty = AABB()
    
    /// The validity of this AABB
    public var validity = PointValidity.invalid
    
    /// Minimum and maximum points for this bounding box
    public var minimum = Vector2.zero
    public var maximum = Vector2.zero
    
    /// Gets the X position of this AABB
    public var x: CGFloat { return minimum.x }
    /// Gets the Y position of this AABB
    public var y: CGFloat { return minimum.y }
    
    /// Gets the width of this AABB
    public var width: CGFloat { return maximum.x - minimum.x }
    /// Gets the height of this AABB
    public var height: CGFloat { return maximum.y - minimum.y }
    
    /// Gets the middle X position of this AABB
    public var midX: CGFloat { return ((minimum + maximum) / 2).x }
    /// Gets the middle Y position of this AABB
    public var midY: CGFloat { return ((minimum + maximum) / 2).y }
    
    // This guy has to be lower case otherwise sourcekit crashes
    /// Gets a CGRect that represents the boundaries of this AABB object
    public var cgRect: CGRect { return CGRect(x: x, y: y, width: width, height: height) }
    
    public init() {
        
    }
    
    public init(min: Vector2, max: Vector2) {
        validity = .valid
      
        minimum = min
        maximum = max
    }
    
    public init(points: [Vector2]) {
        expand(toInclude: points)
    }
    
    public mutating func clear() {
        validity = .invalid
    }
    
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
    
    public func contains(_ point: Vector2) -> Bool {
        if(validity == .invalid) {
            return false
        }
        
        if(point.x >= minimum.x && point.y >= minimum.y) {
            if(point.x <= maximum.x && point.y <= maximum.y) {
                return true
            }
        }
        
        return false
    }
    
    public func intersects(_ box: AABB) -> Bool {
        if(validity == .invalid || box.validity == .invalid) {
            return false
        }
        
        // X overlap check.
        if((minimum.x <= box.maximum.x) && (maximum.x >= box.minimum.x)) {
            // Y overlap check
            if((minimum.y <= box.maximum.y) && (maximum.y >= box.minimum.y)) {
                return true
            }
        }
        
        return false
    }
}

// Specifies the point validity for a whole AABB
public enum PointValidity {
    case valid
    case invalid
}
