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
        self.validity = PointValidity.Valid
      
        self.minimum = min
        self.maximum = max
    }
    
    public init(points: [Vector2])
    {
        self.validity = PointValidity.Invalid
        self.expandToInclude(points)
    }
    
    public mutating func clear()
    {
        self.minimum = Vector2.Zero
        self.maximum = Vector2.Zero
        
        validity = PointValidity.Invalid
    }
    
    public mutating func expandToInclude(point: Vector2)
    {
        if(validity == PointValidity.Invalid)
        {
            self.minimum = point
            self.maximum = point
            
            validity = PointValidity.Valid
        }
        else
        {
            self.minimum = min(self.minimum, point)
            self.maximum = max(self.maximum, point)
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
            self.minimum = points[0]
            self.maximum = points[0]
            
            validity = PointValidity.Valid
        }
        
        for p in points
        {
            self.minimum = min(self.minimum, p)
            self.maximum = max(self.maximum, p)
        }
    }
    
    public func contains(point: Vector2) -> Bool
    {
        if(self.validity == PointValidity.Invalid)
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
        if(self.validity == .Invalid || box.validity == .Invalid)
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