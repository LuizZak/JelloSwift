//
//  Vector2.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics
import simd

/// Specifies an object that can be expressed as a pair of x-y coordinates
public protocol VectorRepresentable {
    /// Gets a vector representation of this object
    var vector: Vector2 { get }
}

/// Represents a 2D vector
public struct Vector2: VectorRepresentable, Equatable, CustomStringConvertible {
    /// A zeroed-value Vector2
    public static let zero = Vector2(0, 0)
    /// An unit-valued Vector2
    public static let unit = Vector2(1, 1)
    
    #if arch(x86_64) || arch(arm64)
    ///Used to match `CGFloat`'s native type
    typealias NativeVectorType = double2
    #else
    ///Used to match `CGFloat`'s native type
    typealias NativeVectorType = float2
    #endif
    
    var theVector: NativeVectorType
    
    public var x: CGFloat {
        get {
            return CGFloat(theVector.x)
        }
        set {
            theVector.x = newValue.native
        }
    }
    public var y: CGFloat {
        get {
            return CGFloat(theVector.y)
        }
        set {
            theVector.y = newValue.native
        }
    }
    
    /// Returns the angle in radians of this Vector2
    public var angle : CGFloat {
        return atan2(y, x)
    }
    
    /// Returns the squared length of this Vector2
    public var length : CGFloat {
        return CGFloat(length_squared(theVector))
    }
    
    /// Returns the magnitude (or square root of the squared length) of this Vector2
    public var magnitude : CGFloat {
        return CGFloat(simd.length(theVector))
    }
    
    public var vector: Vector2 { return self }
    
    public var description: String { return "{ \(self.x) : \(self.y) }" }
    
    public var cgPoint: CGPoint { return CGPoint(x: x, y: y) }
    
    init(_ vector: NativeVectorType) {
        theVector = vector
    }
    
    public init() {
        theVector = NativeVectorType(0)
    }
    
    public init(_ x: Int, _ y: Int) {
        theVector = NativeVectorType(CGFloat.NativeType(x), CGFloat.NativeType(y))
    }
    
    public init(_ x: CGFloat, _ y: CGFloat) {
        theVector = NativeVectorType(x.native, y.native)
    }
    
    public init(_ x: Double, _ y: Double) {
        theVector = NativeVectorType(CGFloat.NativeType(x), CGFloat.NativeType(y))
    }
    
    public init(value: CGFloat) {
        theVector = NativeVectorType(value.native)
    }
    
    public init(_ point: CGPoint) {
        theVector = NativeVectorType(point.x.native, point.y.native)
    }
    
    /// Returns the distance between this Vector2 and another Vector2
    public func distance(to vec: Vector2) -> CGFloat {
        return CGFloat(simd.distance(self.theVector, vec.theVector))
    }
    
    /// Returns the distance squared between this Vector2 and another Vector2
    public func distanceSquared(to vec: Vector2) -> CGFloat {
        return CGFloat(distance_squared(self.theVector, vec.theVector))
    }
    
    /// Makes this Vector2 perpendicular to its current position.
    /// This alters the vector instance
    public mutating func perpendicularize() -> Vector2 {
        self = perpendicular()
        return self
    }
    
    /// Returns a Vector2 perpendicular to this Vector2
    public func perpendicular() -> Vector2 {
        return Vector2(-y, x)
    }
    
    // Normalizes this Vector2 instance.
    // This alters the current vector instance
    public mutating func normalize() -> Vector2 {
        self = normalized()
        return self
    }
    
    /// Returns a normalized version of this Vector2
    public func normalized() -> Vector2 {
        return Vector2(simd.normalize(theVector))
    }
}

/// Dot and Cross products
extension Vector2 {
    /// Calculates the dot product between this and another provided Vector2
    public func dot(with other: Vector2) -> CGFloat {
        return CGFloat(simd.dot(theVector, other.theVector))
    }
    
    /// Calculates the cross product between this and another provided Vector2.
    /// The resulting scalar would match the 'z' axis of the cross product between
    /// 3d vectors matching the x and y coordinates of the operands, with the 'z'
    /// coordinate being 0.
    public func cross(with other: Vector2) -> CGFloat {
        return CGFloat(theVector.x * other.theVector.x - theVector.y * other.theVector.y)
    }
}

extension Vector2 {
    ////
    // Comparision operators
    ////
    static public func ==(lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.theVector.x == rhs.theVector.x && lhs.theVector.y == rhs.theVector.y
    }
    
    // Unary operators
    static public prefix func -(lhs: Vector2) -> Vector2 {
        return Vector2(-lhs.theVector)
    }
    
    // DOT operator
    /// Calculates the dot product between two provided coordinates
    static public func •(lhs: Vector2, rhs: Vector2) -> CGFloat {
        return lhs.dot(with: rhs)
    }
    
    // CROSS operator
    static public func =/(lhs: Vector2, rhs: Vector2) -> CGFloat {
        return lhs.cross(with: rhs)
    }
    
    ////
    // Basic arithmetic operators
    ////
    static public func +(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.theVector + rhs.theVector)
    }
    
    static public func -(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.theVector - rhs.theVector)
    }
    
    static public func *(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.theVector * rhs.theVector)
    }
    
    static public func /(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.theVector / rhs.theVector)
    }
    
    static public func %(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.x.truncatingRemainder(dividingBy: rhs.x), lhs.y.truncatingRemainder(dividingBy: rhs.y))
    }
    
    // CGFloat interaction
    static public func +(lhs: Vector2, rhs: CGFloat) -> Vector2 {
        return Vector2(lhs.theVector + Vector2.NativeVectorType(rhs.native))
    }
    
    static public func -(lhs: Vector2, rhs: CGFloat) -> Vector2 {
        return Vector2(lhs.theVector - Vector2.NativeVectorType(rhs.native))
    }
    
    static public func *(lhs: Vector2, rhs: CGFloat) -> Vector2 {
        return Vector2(lhs.theVector * Vector2.NativeVectorType(rhs.native))
    }
    
    static public func /(lhs: Vector2, rhs: CGFloat) -> Vector2 {
        return Vector2(lhs.theVector / Vector2.NativeVectorType(rhs.native))
    }
    
    static public func %(lhs: Vector2, rhs: CGFloat) -> Vector2 {
        return Vector2(lhs.x.truncatingRemainder(dividingBy: rhs), lhs.y.truncatingRemainder(dividingBy: rhs))
    }
    
    ////
    // Compound assignment operators
    ////
    static public func +=(lhs: inout Vector2, rhs: Vector2) {
        lhs.theVector += rhs.theVector
    }
    static public func -=(lhs: inout Vector2, rhs: Vector2) {
        lhs.theVector -= rhs.theVector
    }
    static public func *=(lhs: inout Vector2, rhs: Vector2) {
        lhs.theVector *= rhs.theVector
    }
    static public func /=(lhs: inout Vector2, rhs: Vector2) {
        lhs.theVector /= rhs.theVector
    }
    
    // CGFloat interaction
    static public func +=(lhs: inout Vector2, rhs: CGFloat) {
        lhs = lhs + rhs
    }
    static public func -=(lhs: inout Vector2, rhs: CGFloat) {
        lhs = lhs - rhs
    }
    static public func *=(lhs: inout Vector2, rhs: CGFloat) {
        lhs = lhs * rhs
    }
    static public func /=(lhs: inout Vector2, rhs: CGFloat) {
        lhs = lhs / rhs
    }
}

extension Vector2 {
    /// Returns a rotated version of this vector, rotated around by a given angle in radians
    public func rotated(by angleInRadians: CGFloat) -> Vector2 {
        return Vector2.rotate(self, by: angleInRadians)
    }
    
    /// Rotates this vector around by a given angle in radians
    public mutating func rotate(by angleInRadians: CGFloat) -> Vector2 {
        self = rotated(by: angleInRadians)
        return self
    }
    
    /// Rotates a given vector by an angle in radians
    public static func rotate(_ vec: Vector2, by angleInRadians: CGFloat) -> Vector2 {
        if(angleInRadians.truncatingRemainder(dividingBy: (CGFloat(M_PI) * 2)) == 0) {
            return vec
        }
        if(angleInRadians.truncatingRemainder(dividingBy: (CGFloat(M_PI) * 2)) == CGFloat(M_PI)) {
            return vec.perpendicular().perpendicular()
        }
        
        let c = cos(angleInRadians)
        let s = sin(angleInRadians)
        
        return Vector2((c * vec.x) - (s * vec.y), (c * vec.y) + (s * vec.x))
    }
}

extension Collection where Iterator.Element: VectorRepresentable, IndexDistance == Int {
    /// Averages this collection of vectors into one Vector2 point
    public func averageVector() -> Vector2 {
        var average = Vector2.zero
        
        for vec in self {
            average += vec.vector
        }
        
        return average / CGFloat(count)
    }
}

/// Returns a Vector2 that represents the minimum coordinates between two Vector2 objects
public func min(_ a: Vector2, _ b: Vector2) -> Vector2 {
    return Vector2(min(a.theVector, b.theVector))
}

/// Returns a Vector2 that represents the maximum coordinates between two Vector2 objects
public func max(_ a: Vector2, _ b: Vector2) -> Vector2 {
    return Vector2(max(a.theVector, b.theVector))
}

/// Returns whether rotating from A to B is counter-clockwise
public func vectorsAreCCW(_ A: Vector2, B: Vector2) -> Bool {
    return (B • A.perpendicular()) >= 0.0
}

////////
//// Define the operations to be performed on the Vector2
////////
infix operator • : MultiplicationPrecedence  // This character is available as 'Option-8' combination on Mac keyboards
infix operator =/ : MultiplicationPrecedence

public func round(_ x: Vector2) -> Vector2 {
    return Vector2(round(x.x), round(x.y))
}

public func ceil(_ x: Vector2) -> Vector2 {
    return Vector2(ceil(x.theVector))
}

public func floor(_ x: Vector2) -> Vector2 {
    return Vector2(floor(x.theVector))
}

public func abs(_ x: Vector2) -> Vector2 {
    return Vector2(abs(x.theVector))
}
