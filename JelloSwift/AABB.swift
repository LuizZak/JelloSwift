//
//  AABB.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Represents an axis-aligned bounding box, utilized to figure out the AABB of soft-bodies
final class AABB
{
    /// The validity of this AABB
    var validity = PointValidity.Invalid;
    
    /// Minimum and maximum points for this bounding box
    var minimum = Vector2();
    var maximum = Vector2();
    
    /// Gets the X position of this AABB
    var x: CGFloat { return minimum.X; }
    /// Gets the Y position of this AABB
    var y: CGFloat { return minimum.Y; }
    
    /// Gets the width of this AABB
    var width: CGFloat { return maximum.X - minimum.X; }
    /// Gets the height of this AABB
    var height: CGFloat { return maximum.Y - minimum.Y; }
    
    // This guy has to be lower case otherwise sourcekit crashes
    /// Gets a CGRect that represents the boundaries of this AABB object
    var cgRect: CGRect { return CGRect(x: x, y: y, width: width, height: height) }
    
    init()
    {
        
    }
    
    init(min: Vector2?, max: Vector2?)
    {
        self.validity = PointValidity.Valid;
        
        if let mi = min
        {
            self.minimum = mi;
        }
        else
        {
            self.validity = PointValidity.Invalid;
        }
        
        if let ma = max
        {
            self.maximum = ma;
        }
        else
        {
            self.validity = PointValidity.Invalid;
        }
    }
    
    init(points: [Vector2])
    {
        self.validity = PointValidity.Invalid;
        self.expandToInclude(points);
    }
    
    func clear()
    {
        self.minimum = Vector2();
        self.maximum = Vector2();
        
        validity = PointValidity.Invalid;
    }
    
    func expandToInclude(point: Vector2)
    {
        if(validity == PointValidity.Invalid)
        {
            self.minimum = point;
            self.maximum = point;
            
            validity = PointValidity.Valid;
        }
        else
        {
            self.minimum = min(self.minimum, point);
            self.maximum = max(self.maximum, point);
        }
    }
    
    func expandToInclude(points: [Vector2])
    {
        if(points.count == 0)
        {
            return;
        }
        
        if(validity == PointValidity.Invalid)
        {
            self.minimum = points[0];
            self.maximum = points[0];
            
            validity = PointValidity.Valid;
        }
        
        for p in points
        {
            self.minimum = min(self.minimum, p);
            self.maximum = max(self.maximum, p);
        }
    }
    
    func contains(point: Vector2) -> Bool
    {
        if(self.validity == PointValidity.Invalid)
        {
            return false;
        }
        
        return point >= minimum && point <= maximum;
    }
    
    func intersects(box: AABB) -> Bool
    {
        return self.minimum <= box.maximum && self.maximum >= box.minimum;
    }
}

// Specifies the point validity for a whole AABB
enum PointValidity
{
    case Valid
    case Invalid
}