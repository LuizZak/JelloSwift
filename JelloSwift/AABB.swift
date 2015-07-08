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
    public var validity = PointValidity.Invalid
    
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
        validity = PointValidity.Valid
      
        minimum = min
        maximum = max
    }
    
    public init(points: [Vector2])
    {
        validity = PointValidity.Invalid
        expandToInclude(points)
    }
    
    public mutating func clear()
    {
        minimum = Vector2.Zero
        maximum = Vector2.Zero
        
        validity = PointValidity.Invalid
    }
    
    public mutating func expandToInclude(point: Vector2)
    {
        if(validity == PointValidity.Invalid)
        {
            minimum = point
            maximum = point
            
            validity = PointValidity.Valid
        }
        else
        {
            minimum = min(minimum, point)
            maximum = max(maximum, point)
        }
    }
    
    public mutating func expandToInclude(points: [Vector2])
    {
        if(points.count == 0)
        {
            return
        }
        
        if(validity == PointValidity.Invalid)
        {
            minimum = points[0]
            maximum = points[0]
            
            validity = PointValidity.Valid
        }
        
        for p in points
        {
            minimum = min(minimum, p)
            maximum = max(maximum, p)
        }
    }
    
    public func contains(point: Vector2) -> Bool
    {
        if(validity == PointValidity.Invalid)
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
    
    public func intersects(box: AABB) -> Bool
    {
        if(validity == .Invalid || box.validity == .Invalid)
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
    case Valid
    case Invalid
}