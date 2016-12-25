//
//  Vector2.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics
import simd

/// Represents a 2D vector
public struct Vector2: Equatable, CustomStringConvertible
{
    /// A zeroed-value Vector2
    public static let Zero = Vector2(0, 0)
    /// A one-valued Vector2
    public static let One = Vector2(1, 1)
    
    #if arch(x86_64) || arch(arm64)
    ///Used to match `CGFloat`'s native type
    typealias NativeVectorType = double2
    #else
    ///Used to match `CGFloat`'s native type
    typealias NativeVectorType = float2
    #endif
    
    var theVector: NativeVectorType
    
    public var X: CGFloat {
        get {
            return CGFloat(theVector.x)
        }
        set {
            theVector.x = newValue.native
        }
    }
    public var Y: CGFloat {
        get {
            return CGFloat(theVector.y)
        }
        set {
            theVector.y = newValue.native
        }
    }
    
    public var description: String { return "{ \(self.X) : \(self.Y) }" }
    
    public var cgPoint: CGPoint { return CGPoint(x: X, y: Y) }
    
    init(_ vector: NativeVectorType) {
        theVector = vector
    }
    
    public init()
    {
        theVector = NativeVectorType(0)
    }
    
    public init(_ x: Int, _ y: Int)
    {
        theVector = NativeVectorType(CGFloat.NativeType(x), CGFloat.NativeType(y))
    }
    
    public init(_ x: CGFloat, _ y: CGFloat)
    {
        theVector = NativeVectorType(x.native, y.native)
    }
    
    public init(_ x: Double, _ y: Double)
    {
        theVector = NativeVectorType(CGFloat.NativeType(x), CGFloat.NativeType(y))
    }
    
    public init(value: CGFloat)
    {
        theVector = NativeVectorType(value.native)
    }
    
    public init(_ point: CGPoint)
    {
        theVector = NativeVectorType(point.x.native, point.y.native)
    }
    
    /// Returns the angle in radians of this Vector2
    public func angle() -> CGFloat
    {
        return atan2(Y, X)
    }
    
    /// Returns the squared length of this Vector2
    public func length() -> CGFloat
    {
        return CGFloat(length_squared(theVector))
    }
    
    /// Returns the magnitude (or square root of the squared length) of this Vector2
    public func magnitude() -> CGFloat
    {
        return CGFloat(simd.length(theVector))
    }
    
    /// Returns the distance between this Vector2 and another Vector2
    public func distanceTo(_ vec: Vector2) -> CGFloat
    {
        return CGFloat(distance(self.theVector, vec.theVector))
    }
    
    /// Returns the distance squared between this Vector2 and another Vector2
    public func distanceToSquared(_ vec: Vector2) -> CGFloat
    {
        return CGFloat(distance_squared(self.theVector, vec.theVector))
    }
    
    /// Makes this Vector2 perpendicular to its current position.
    /// This alters the vector instance
    public mutating func perpendicularThis() -> Vector2
    {
        self = perpendicular()
        
        return self
    }
    
    /// Returns a Vector2 perpendicular to this Vector2
    public func perpendicular() -> Vector2
    {
        return Vector2(-theVector.y, theVector.x)
    }
    
    // Normalizes this Vector2 instance.
    // This alters the current vector instance
    public mutating func normalizeThis() -> Vector2
    {
        self = normalized()
        
        return self
    }
    
    /// Returns a normalized version of this Vector2
    public func normalized() -> Vector2
    {
        return Vector2(normalize(theVector))
    }
}

/// Dot and Cross products
extension Vector2
{
    /// Calculates the dot product between this and another provided Vector2
    public func dot(with other: Vector2) -> CGFloat
    {
        return CGFloat(simd.dot(theVector, other.theVector))
    }
    
    /// Calculates the cross product between this and another provided Vector2.
    /// The resulting scalar would match the 'z' axis of the cross product between
    /// 3d vectors matching the x and y coordinates of the operands, with the 'z'
    /// coordinate being 0.
    public func cross(with other: Vector2) -> CGFloat
    {
        return CGFloat(theVector.x * other.theVector.x - theVector.y * other.theVector.y)
    }
}

extension Vector2
{
    func rotate(_ angleInRadians: CGFloat) -> Vector2
    {
        return rotateVector(self, angleInRadians: Double(angleInRadians))
    }
}

/// Returns a Vector2 that represents the minimum coordinates between two Vector2 objects
public func min(_ a: Vector2, _ b: Vector2) -> Vector2
{
    return Vector2(min(a.theVector, b.theVector))
}

/// Returns a Vector2 that represents the maximum coordinates between two Vector2 objects
public func max(_ a: Vector2, _ b: Vector2) -> Vector2
{
    return Vector2(max(a.theVector, b.theVector))
}

/// Rotates a given vector by an angle in radians
public func rotateVector(_ vec: Vector2, angleInRadians: CGFloat) -> Vector2
{
    return rotateVector(vec, angleInRadians: Double(angleInRadians))
}

public func rotateVector(_ vec: Vector2, angleInRadians: Double) -> Vector2
{
    if(angleInRadians.truncatingRemainder(dividingBy: (M_PI * 2)) == 0)
    {
        return vec
    }
    
    let c = CGFloat(cos(angleInRadians))
    let s = CGFloat(sin(angleInRadians))
    
    let newX: CGFloat = (c * vec.X) - (s * vec.Y)
    let newY: CGFloat = (c * vec.Y) + (s * vec.X)
    
    return Vector2(newX, newY)
}

/// Returns whether rotating from A to B is counter-clockwise
public func vectorsAreCCW(_ A: Vector2, B: Vector2) -> Bool
{
    return (B • A.perpendicular()) >= 0.0
}

/// Averages a list of vectors into one normalized Vector2 point
public func averageVectors<T: Collection>(_ vectors: T) -> Vector2 where T.Iterator.Element == Vector2, T.IndexDistance == Int
{
    return vectors.reduce(Vector2.Zero, +) / CGFloat(vectors.count)
}

////////
//// Define the operations to be performed on the Vector2
////////
infix operator • : MultiplicationPrecedence
infix operator =/ : MultiplicationPrecedence

////
// Comparision operators
////
public func ==(lhs: Vector2, rhs: Vector2) -> Bool
{
    return funcOnVectors(lhs, rhs, ==)
}

// Unary operators
public prefix func -(lhs: Vector2) -> Vector2
{
    return Vector2(-lhs.theVector)
}

// DOT operator
/// Calculates the dot product between two provided coordinates
public func •(lhs: Vector2, rhs: Vector2) -> CGFloat
{
    return lhs.dot(with: rhs)
}

// CROSS operator
public func =/(lhs: Vector2, rhs: Vector2) -> CGFloat
{
    return lhs.cross(with: rhs)
}

////
// Basic arithmetic operators
////
public func +(lhs: Vector2, rhs: Vector2) -> Vector2
{
    return Vector2(lhs.theVector + rhs.theVector)
}

public func -(lhs: Vector2, rhs: Vector2) -> Vector2
{
    return Vector2(lhs.theVector - rhs.theVector)
}

public func *(lhs: Vector2, rhs: Vector2) -> Vector2
{
    return Vector2(lhs.theVector * rhs.theVector)
}

public func /(lhs: Vector2, rhs: Vector2) -> Vector2
{
    return Vector2(lhs.theVector / rhs.theVector)
}

public func %(lhs: Vector2, rhs: Vector2) -> Vector2
{
    return Vector2(lhs.X.truncatingRemainder(dividingBy: rhs.X), lhs.Y.truncatingRemainder(dividingBy: rhs.Y))
}

// CGFloat interaction
public func +(lhs: Vector2, rhs: CGFloat) -> Vector2
{
    return Vector2(lhs.theVector + Vector2.NativeVectorType(rhs.native))
}

public func -(lhs: Vector2, rhs: CGFloat) -> Vector2
{
    return Vector2(lhs.theVector - Vector2.NativeVectorType(rhs.native))
}

public func *(lhs: Vector2, rhs: CGFloat) -> Vector2
{
    return Vector2(lhs.theVector * Vector2.NativeVectorType(rhs.native))
}

public func /(lhs: Vector2, rhs: CGFloat) -> Vector2
{
    return Vector2(lhs.theVector / Vector2.NativeVectorType(rhs.native))
}

public func %(lhs: Vector2, rhs: CGFloat) -> Vector2
{
    return Vector2(lhs.X.truncatingRemainder(dividingBy: rhs), lhs.Y.truncatingRemainder(dividingBy: rhs))
}

private func funcOnVectors(_ lhs: Vector2, _ rhs: Vector2, _ f: (CGFloat, CGFloat) -> CGFloat) -> Vector2
{
    return Vector2(f(lhs.X, rhs.X), f(lhs.Y, rhs.Y))
}

private func funcOnVectors(_ lhs: Vector2, _ rhs: CGFloat, _ f: (CGFloat, CGFloat) -> CGFloat) -> Vector2
{
    return Vector2(f(lhs.X, rhs), f(lhs.Y, rhs))
}

private func funcOnVectors(_ lhs: Vector2, _ rhs: Vector2, _ f: (CGFloat, CGFloat) -> Bool) -> Bool
{
    return f(lhs.X, rhs.X) && f(lhs.Y, rhs.Y)
}

////
// Compound assignment operators
////
public func +=(lhs: inout Vector2, rhs: Vector2)
{
    lhs.theVector += rhs.theVector
}
public func -=(lhs: inout Vector2, rhs: Vector2)
{
    lhs.theVector -= rhs.theVector
}
public func *=(lhs: inout Vector2, rhs: Vector2)
{
    lhs.theVector *= rhs.theVector
}
public func /=(lhs: inout Vector2, rhs: Vector2)
{
    lhs.theVector /= rhs.theVector
}

// CGFloat interaction
public func +=(lhs: inout Vector2, rhs: CGFloat)
{
    lhs = lhs + rhs
}
public func -=(lhs: inout Vector2, rhs: CGFloat)
{
    lhs = lhs - rhs
}
public func *=(lhs: inout Vector2, rhs: CGFloat)
{
    lhs = lhs * rhs
}
public func /=(lhs: inout Vector2, rhs: CGFloat)
{
    lhs = lhs / rhs
}

public func round(_ x: Vector2) -> Vector2
{
    return Vector2(round(x.X), round(x.Y))
}

public func ceil(_ x: Vector2) -> Vector2
{
    return Vector2(ceil(x.theVector))
}

public func floor(_ x: Vector2) -> Vector2
{
    return Vector2(floor(x.theVector))
}

public func abs(_ x: Vector2) -> Vector2
{
    return Vector2(abs(x.theVector))
}
