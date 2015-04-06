//
//  Vector3.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Represents a 3D vector
public struct Vector3: Equatable, Printable
{
    public var X: CGFloat = 0;
    public var Y: CGFloat = 0;
    public var Z: CGFloat = 0;
    
    public var description: String
    {
        return "{ X: \(X) Y: \(Y) Z: \(Z) }";
    }
    
    public init()
    {
        
    }
    
    public init(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat)
    {
        self.X = x;
        self.Y = y;
        self.Z = z;
    }
    
    public init(vec2: Vector2, z: CGFloat = 0)
    {
        self.X = vec2.X;
        self.Y = vec2.Y;
        self.Z = z;
    }
    
    public func cross2Z(vec: Vector3) -> CGFloat
    {
        return (self.X * vec.Y) - (self.Y * vec.X);
    }
}

public func ==(lhs: Vector3, rhs: Vector3) -> Bool
{
    return lhs.X == rhs.X && lhs.Y == rhs.Y && lhs.Z == rhs.Z;
}

// CROSS operator
public func =/(lhs: Vector3, rhs: Vector3) -> Vector3
{
    var yz = (lhs.Y * rhs.Z) - (lhs.Z * rhs.Y)
    var xz = (lhs.Z * rhs.X) - (lhs.X * rhs.Z)
    var xy = (lhs.X * rhs.Y) - (lhs.Y * rhs.X)
    
    return Vector3(yz, xz, xy);
}