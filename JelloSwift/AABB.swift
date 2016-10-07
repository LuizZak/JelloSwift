//
//  AABB.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Represents an axis-aligned bounding box, utilized to figure out the AABB of soft-bodies
public struct AABB
{
    /// The validity of this AABB
    public var validity = PointValidity.invalid
    
    /// Minimum and maximum points for this bounding box
    public var minimum = Vector2.Zero
    public var maximum = Vector2.Zero
    
    /// Gets the X position of this AABB
    public var x: CGFloat { return minimum.X }
    /// Gets the Y position of this AABB
    public var y: CGFloat { return minimum.Y }
    
    /// Gets the width of this AABB
    public var width: CGFloat { return maximum.X - minimum.X }
    /// Gets the height of this AABB
    public var height: CGFloat { return maximum.Y - minimum.Y }
    
    /// Gets the middle X position of this AABB
    public var midX: CGFloat { return ((minimum + maximum) / 2).X }
    /// Gets the middle Y position of this AABB
    public var midY: CGFloat { return ((minimum + maximum) / 2).Y }
    
    // This guy has to be lower case otherwise sourcekit crashes
    /// Gets a CGRect that represents the boundaries of this AABB object
    public var cgRect: CGRect { return CGRect(x: x, y: y, width: width, height: height) }
    
    public init()
    {
        
    }
    
    public init(min: Vector2, max: Vector2)
    {
        validity = PointValidity.valid
      
        minimum = min
        maximum = max
    }
    
    public init(points: [Vector2])
    {
        validity = PointValidity.invalid
        expandToInclude(points)
    }
    
    public mutating func clear()
    {
        minimum = Vector2.Zero
        maximum = Vector2.Zero
        
        validity = PointValidity.invalid
    }
    
    public mutating func expandToInclude(_ point: Vector2)
    {
        if(validity == PointValidity.invalid)
        {
            minimum = point
            maximum = point
            
            validity = PointValidity.valid
        }
        else
        {
            minimum = min(minimum, point)
            maximum = max(maximum, point)
        }
    }
    
    public mutating func expandToInclude(_ points: [Vector2])
    {
        if(points.count == 0)
        {
            return
        }
        
        if(validity == PointValidity.invalid)
        {
            minimum = points[0]
            maximum = points[0]
            
            validity = PointValidity.valid
        }
        
        for p in points
        {
            minimum = min(minimum, p)
            maximum = max(maximum, p)
        }
    }
    
    public func contains(_ point: Vector2) -> Bool
    {
        if(validity == PointValidity.invalid)
        {
            return false
        }
        
        if(point.X >= minimum.X && point.Y >= minimum.Y)
        {
            if(point.X <= maximum.X && point.Y <= maximum.Y)
            {
                return true
            }
        }
        
        return false
    }
    
    public func intersects(_ box: AABB) -> Bool
    {
        if(validity == .invalid || box.validity == .invalid)
        {
            return false
        }
        
        // X overlap check.
        if((minimum.X <= box.maximum.X) && (maximum.X >= box.minimum.X))
        {
            // Y overlap check
            if((minimum.Y <= box.maximum.Y) && (maximum.Y >= box.minimum.Y))
            {
                return true;
            }
        }
        
        return false;
    }
}

// Specifies the point validity for a whole AABB
public enum PointValidity
{
    case valid
    case invalid
}
