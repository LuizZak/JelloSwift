//
//  Vector2.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Represents a 2D vector
struct Vector2: Equatable, Printable
{
    var X: CGFloat;
    var Y: CGFloat;
    var description: String { return toString(); };
    
    init(_ x:CGFloat = 0, _ y:CGFloat = 0)
    {
        self.X = x;
        self.Y = y;
    }
    
    init(_ num:CGFloat)
    {
        self.X = num;
        self.Y = num;
    }
    
    // Returns the magnitude of this Vector2
    func magnitude() -> CGFloat
    {
        return sqrt(length());
    }
    
    // Retunrs the angle of this Vector2
    func angle() -> CGFloat
    {
        return atan2(Y, X);
    }
    
    // Returns the length of this Vector2
    func length() -> CGFloat
    {
        return X * X + Y * Y;
    }
    
    // Returns the distance between this Vector2 and another Vector2
    func distance(vec: Vector2) -> CGFloat
    {
        return (self - vec).magnitude();
    }
    
    // Returns the distance squared between this Vector2 and another Vector2
    func distanceSquared(vec: Vector2) -> CGFloat
    {
        return (self - vec).length();
    }
    
    // Makes this Vector2 perpendicular to its current position.
    // This alters the vector instance
    mutating func perpendicularThis() -> Vector2
    {
        self = perpendicular();
        
        return self;
    }
    
    // Returns a Vector2 perpendicular to this Vector2
    func perpendicular() -> Vector2
    {
        return Vector2(-Y, X);
    }
    
    // Normalizes this Vector2 instance.
    // This alters the current vector instance
    mutating func normalizeThis() -> Vector2
    {
        self = normalized();
        
        return self;
    }
    
    // Returns a normalized version of this Vector2
    func normalized() -> Vector2
    {
        var x = X;
        var y = Y;
        var mag = magnitude();
        
        if(mag > 0.0000001)
        {
            x /= mag;
            y /= mag;
        }
        
        return Vector2(x, y);
    }
    
    // Returns a string representation of this Vector2 value
    func toString() -> String
    {
        var str:NSMutableString = "";
        
        
        str.appendString("{ ");
        
        if(isnan(X))
        {
            str.appendString("nan");
        }
        else
        {
            str.appendFormat("%@", X.description);
        }
        
        str.appendString(" : ");
        
        if(isnan(Y))
        {
            str.appendString("nan");
        }
        else
        {
            str.appendFormat("%@", Y.description);
        }
        
        str.appendString(" }");
        
        return str;
    }
}

let Vector2Zero = Vector2(0, 0);
let Vector2One = Vector2(1, 1);

// Rotates a given vector by an angle in radians
func rotateVector(vec: Vector2, angleInRadians: CGFloat) -> Vector2
{
    if(angleInRadians % (PI * 2) == 0)
    {
        return vec;
    }
    
    var ret = Vector2();
    
    var c = cos(angleInRadians);
    var s = sin(angleInRadians);
    
    ret.X = (c * vec.X) - (s * vec.Y);
    ret.Y = (c * vec.Y) + (s * vec.X);
    
    return ret;
}

// Returns whether rotating from A to B is counter-clockwise
func vectorsAreCCW(A: Vector2, B: Vector2) -> Bool
{
    var perp = A.perpendicular();
    
    return (B =* perp) >= 0.0;
}

// Averages a list of vectors into one Vector2 point
func averageVectors(vectors: [Vector2]) -> Vector2
{
    var vec:Vector2 = Vector2();
    
    for v in vectors
    {
        vec += v;
    }
    
    vec /= vectors.count;
    
    vec.normalizeThis();
    
    return vec;
}

////////
//// Define the operations to be performed on the Vector2
////////
infix operator =* { associativity left precedence 150 }
infix operator =/ { associativity left precedence 151 }

////
// Equality operators
////
func ==(lhs: Vector2, rhs: Vector2) -> Bool
{
    return lhs.X == rhs.X && lhs.Y == rhs.Y;
}

func >=(lhs: Vector2, rhs: Vector2) -> Bool
{
    return lhs.X >= rhs.X && lhs.Y >= rhs.Y;
}
func <=(lhs: Vector2, rhs: Vector2) -> Bool
{
    return lhs.X <= rhs.X && lhs.Y <= rhs.Y;
}
func >(lhs: Vector2, rhs: Vector2) -> Bool
{
    return lhs.X > rhs.X && lhs.Y > rhs.Y;
}
func <(lhs: Vector2, rhs: Vector2) -> Bool
{
    return lhs.X < rhs.X && lhs.Y < rhs.Y;
}

// Unary operators
prefix func -(lhs: Vector2) -> Vector2
{
    return Vector2(-lhs.X, -lhs.Y);
}

// DOT operator
func =*(lhs: Vector2, rhs: Vector2) -> CGFloat
{
    return lhs.X * rhs.X + lhs.Y * rhs.Y;
}

// CROSS operator
func =/(lhs: Vector2, rhs: Vector2) -> CGFloat
{
    return lhs.X * rhs.X - lhs.Y * rhs.Y;
}

////
// Basic arithmetic operators
////
func +(lhs: Vector2, rhs: Vector2) -> Vector2
{
    return Vector2(lhs.X + rhs.X, lhs.Y + rhs.Y);
}
func -(lhs: Vector2, rhs: Vector2) -> Vector2
{
    return Vector2(lhs.X - rhs.X, lhs.Y - rhs.Y);
}
func *(lhs: Vector2, rhs: Vector2) -> Vector2
{
    return Vector2(lhs.X * rhs.X, lhs.Y * rhs.Y);
}
func /(lhs: Vector2, rhs: Vector2) -> Vector2
{
    return Vector2(lhs.X / rhs.X, lhs.Y / rhs.Y);
}

// CGFloat interaction
func +(lhs: Vector2, rhs: CGFloat) -> Vector2
{
    return Vector2(lhs.X + rhs, lhs.Y + rhs);
}
func -(lhs: Vector2, rhs: CGFloat) -> Vector2
{
    return Vector2(lhs.X - rhs, lhs.Y - rhs);
}
func *(lhs: Vector2, rhs: CGFloat) -> Vector2
{
    return Vector2(lhs.X * rhs, lhs.Y * rhs);
}
func /(lhs: Vector2, rhs: CGFloat) -> Vector2
{
    return Vector2(lhs.X / rhs, lhs.Y / rhs);
}

// CGFloat interaction
func +(lhs: Vector2, rhs: Int) -> Vector2
{
    return lhs + CGFloat(rhs);
}
func -(lhs: Vector2, rhs: Int) -> Vector2
{
    return lhs - CGFloat(rhs);
}
func *(lhs: Vector2, rhs: Int) -> Vector2
{
    return lhs * CGFloat(rhs);
}
func /(lhs: Vector2, rhs: Int) -> Vector2
{
    return lhs / CGFloat(rhs);
}

////
// Compound assignment operators
////
func +=(inout lhs: Vector2, rhs: Vector2)
{
    lhs = lhs + rhs;
}
func -=(inout lhs: Vector2, rhs: Vector2)
{
    lhs = lhs - rhs;
}
func *=(inout lhs: Vector2, rhs: Vector2)
{
    lhs = lhs * rhs;
}
func /=(inout lhs: Vector2, rhs: Vector2)
{
    lhs = lhs / rhs;
}

// CGFloat interaction
func +=(inout lhs: Vector2, rhs: CGFloat)
{
    lhs = lhs + rhs;
}
func -=(inout lhs: Vector2, rhs: CGFloat)
{
    lhs = lhs - rhs;
}
func *=(inout lhs: Vector2, rhs: CGFloat)
{
    lhs = lhs * rhs;
}
func /=(inout lhs: Vector2, rhs: CGFloat)
{
    lhs = lhs / rhs;
}

// CGFloat interaction
func +=(inout lhs: Vector2, rhs: Int)
{
    lhs = lhs + rhs;
}
func -=(inout lhs: Vector2, rhs: Int)
{
    lhs = lhs - rhs;
}
func *=(inout lhs: Vector2, rhs: Int)
{
    lhs = lhs * rhs;
}
func /=(inout lhs: Vector2, rhs: Int)
{
    lhs = lhs / rhs;
}