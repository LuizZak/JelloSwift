//
//  AABB.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Represents an axis-aligned bounding box, utilized to figure out the AABB of soft-bodies
class AABB: NSObject
{
    // The validity of this AABB
    var validity = PointValidity.Invalid;
    
    // Minimum and maximum points for this bounding box
    var minimum = Vector2();
    var maximum = Vector2();
    
    // Gets the width of this AABB
    var width: CGFloat { get { return maximum.X - minimum.X; } }
    // Gets the height of this AABB
    var height: CGFloat { get { return maximum.Y - minimum.Y; } }
    
    override init()
    {
        super.init();
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
        
        super.init();
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
            self.minimum.X = min(self.minimum.X, point.X);
            self.minimum.Y = min(self.minimum.Y, point.Y);
            
            self.maximum.X = max(self.maximum.X, point.X);
            self.maximum.Y = max(self.maximum.Y, point.Y);
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