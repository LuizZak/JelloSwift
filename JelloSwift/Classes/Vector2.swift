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

#if arch(x86_64) || arch(arm64)
/// Represents the standard floating point type used by JelloSwift.
/// It is a double precision floating point in 64-bits platforms, and
/// single-precision in 32-bit platforms.
///
/// Currently: Double
public typealias JFloat = Double
#else
/// Represents the standard floating point type used by JelloSwift.
/// It is a double precision floating point in 64-bits platforms, and
/// single-precision in 32-bit platforms.
///
/// Currently: Float
public typealias JFloat = Float
#endif

/// Represents a 2D vector
public struct Vector2: VectorRepresentable, Equatable, CustomStringConvertible {
    
    /// A zeroed-value Vector2
    public static let zero = Vector2(x: 0, y: 0)
    
    /// An unit-valued Vector2
    public static let unit = Vector2(x: 1, y: 1)
    
    #if arch(x86_64) || arch(arm64)
    /// Used to match `JFloat`'s native type
    public typealias NativeVectorType = double2
    
    /// The 3x3 matrix type that can be used to apply transformations by
    /// multiplying on this Vector2
    public typealias NativeMatrixType = double3x3
    
    /// C matrix type
    public typealias NativeCMatrixType = matrix_double3x3
    
    /// This is used during affine transformation
    typealias HomogenousVectorType = double3
    #else
    ///Used to match `JFloat`'s native type
    public typealias NativeVectorType = float2
    
    /// The 3x3 matrix type that can be used to apply transformations by
    /// multiplying on this Vector2
    public typealias NativeMatrixType = float3x3
    
    /// C matrix type
    public typealias NativeCMatrixType = matrix_float3x3
    
    /// This is used during affine transformation
    typealias HomogenousVectorType = float3
    #endif
    
    /// The underlying SIMD vector type
    @_versioned
    var theVector: NativeVectorType
    
    /// The JFloat representation of this vector's x axis
    @_transparent
    public var x: JFloat {
        get {
            return theVector.x
        }
        set {
            theVector.x = newValue
        }
    }
    
    /// The JFloat representation of this vector's y axis
    @_transparent
    public var y: JFloat {
        get {
            return theVector.y
        }
        set {
            theVector.y = newValue
        }
    }
    
    /// Returns the angle in radians of this Vector2
    @_transparent
    public var angle : JFloat {
        return atan2(y, x)
    }
    
    /// Returns the squared length of this Vector2
    @_transparent
    public var length : JFloat {
        return length_squared(theVector)
    }
    
    /// Returns the magnitude (or square root of the squared length) of this 
    /// Vector2
    @_transparent
    public var magnitude : JFloat {
        return simd.length(theVector)
    }
    
    /// For conformance to VectorRepresentable - always returns self
    public var vector: Vector2 {
        return self
    }
    
    /// Textual representation of this vector's coordinates
    public var description: String {
        return "{ \(self.x) : \(self.y) }"
    }
    
    /// Utility property for getting a CGPoint that matches this vector's 
    /// coordinates
    public var cgPoint: CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
    
    @_versioned
    init(_ vector: NativeVectorType) {
        theVector = vector
    }
    
    /// Inits a 0-valued Vector2
    public init() {
        theVector = NativeVectorType(0)
    }
    
    /// Inits a vector 2 with two integer components
    public init(x: Int, y: Int) {
        theVector = NativeVectorType(JFloat(x), JFloat(y))
    }
    
    /// Inits a vector 2 with two float components
    public init(x: CGFloat, y: CGFloat) {
        theVector = NativeVectorType(x.native, y.native)
    }
    
    /// Inits a vector 2 with two float components
    public init(x: Float, y: Float) {
        theVector = NativeVectorType(JFloat(x), JFloat(y))
    }
    
    /// Inits a vector 2 with two double-precision floating point components
    public init(x: Double, y: Double) {
        theVector = NativeVectorType(JFloat(x), JFloat(y))
    }
    
    /// Inits a vector 2 with X and Y defined as a given float
    public init(value: JFloat) {
        theVector = NativeVectorType(value)
    }
    
    /// Inits a vector 2 with a CGPoint
    public init(_ point: CGPoint) {
        theVector = NativeVectorType(point.x.native, point.y.native)
    }
    
    /// Returns the distance between this Vector2 and another Vector2
    @_transparent
    public func distance(to vec: Vector2) -> JFloat {
        return simd.distance(self.theVector, vec.theVector)
    }
    
    /// Returns the distance squared between this Vector2 and another Vector2
    @_transparent
    public func distanceSquared(to vec: Vector2) -> JFloat {
        return distance_squared(self.theVector, vec.theVector)
    }
    
    /// Makes this Vector2 perpendicular to its current position.
    /// This alters the vector instance
    @_transparent
    public mutating func formPerpendicular() -> Vector2 {
        self = perpendicular()
        return self
    }
    
    /// Returns a Vector2 perpendicular to this Vector2
    @_transparent
    public func perpendicular() -> Vector2 {
        return Vector2(x: -y, y: x)
    }
    
    // Normalizes this Vector2 instance.
    // This alters the current vector instance
    @_transparent
    public mutating func normalize() -> Vector2 {
        self = normalized()
        return self
    }
    
    /// Returns a normalized version of this Vector2
    @_transparent
    public func normalized() -> Vector2 {
        return Vector2(simd.normalize(theVector))
    }
}

/// Dot and Cross products
extension Vector2 {
    /// Calculates the dot product between this and another provided Vector2
    public func dot(_ other: Vector2) -> JFloat {
        return simd.dot(theVector, other.theVector)
    }
    
    /// Calculates the cross product between this and another provided Vector2.
    /// The resulting scalar would match the 'z' axis of the cross product 
    /// between
    /// 3d vectors matching the x and y coordinates of the operands, with the 
    /// 'z' coordinate being 0.
    public func cross(_ other: Vector2) -> JFloat {
        return theVector.x * other.theVector.x - theVector.y * other.theVector.y
    }
}

// MARK: Operators
extension Vector2 {
    ////
    // Comparision operators
    ////
    static public func ==(lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.theVector.x == rhs.theVector.x && lhs.theVector.y == rhs.theVector.y
    }
    
    // Unary operators
    @_transparent
    static public prefix func -(lhs: Vector2) -> Vector2 {
        return Vector2(-lhs.theVector)
    }
    
    // DOT operator
    /// Calculates the dot product between two provided coordinates.
    /// See `Vector2.dot`
    @_transparent
    static public func •(lhs: Vector2, rhs: Vector2) -> JFloat {
        return lhs.dot(rhs)
    }
    
    // CROSS operator
    /// Calculates the dot product between two provided coordinates
    /// See `Vector2.cross`
    @_transparent
    static public func =/(lhs: Vector2, rhs: Vector2) -> JFloat {
        return lhs.cross(rhs)
    }
    
    ////
    // Basic arithmetic operators
    ////
    @_transparent
    static public func +(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.theVector + rhs.theVector)
    }
    
    @_transparent
    static public func -(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.theVector - rhs.theVector)
    }
    
    @_transparent
    static public func *(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.theVector * rhs.theVector)
    }
    
    @_transparent
    static public func /(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(lhs.theVector / rhs.theVector)
    }
    
    @_transparent
    static public func %(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(x: lhs.x.truncatingRemainder(dividingBy: rhs.x),
                       y: lhs.y.truncatingRemainder(dividingBy: rhs.y))
    }
    
    // JFloat interaction
    @_transparent
    static public func +(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(lhs.theVector + Vector2.NativeVectorType(rhs))
    }
    
    @_transparent
    static public func -(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(lhs.theVector - Vector2.NativeVectorType(rhs))
    }
    
    @_transparent
    static public func *(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(lhs.theVector * Vector2.NativeVectorType(rhs))
    }
    
    @_transparent
    static public func /(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(lhs.theVector / Vector2.NativeVectorType(rhs))
    }
    
    @_transparent
    static public func %(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(x: lhs.x.truncatingRemainder(dividingBy: rhs),
                       y: lhs.y.truncatingRemainder(dividingBy: rhs))
    }
    
    @_transparent
    static public func /(lhs: JFloat, rhs: Vector2) -> Vector2 {
        return Vector2(x: lhs / rhs.x, y: lhs / rhs.y)
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
    
    // JFloat interaction
    static public func +=(lhs: inout Vector2, rhs: JFloat) {
        lhs = lhs + rhs
    }
    static public func -=(lhs: inout Vector2, rhs: JFloat) {
        lhs = lhs - rhs
    }
    static public func *=(lhs: inout Vector2, rhs: JFloat) {
        lhs = lhs * rhs
    }
    static public func /=(lhs: inout Vector2, rhs: JFloat) {
        lhs = lhs / rhs
    }
}

// MARK: Matrix-transformation
extension Vector2 {
    
    /// Creates a matrix that when multiplied with a Vector2 object applies the
    /// given set of transformations.
    ///
    /// If all default values are set, an identity matrix is created, which does
    /// not alter a Vector2's coordinates once applied.
    ///
    /// The order of operations are: scaling -> rotation -> translation
    static public func matrix(scalingBy scale: Vector2 = Vector2.unit,
                              rotatingBy angle: JFloat = 0,
                              translatingBy translate: Vector2 = Vector2.zero) -> Vector2.NativeMatrixType {
        
        var matrix = Vector2.NativeMatrixType(1)
        
        // Prepare matrices
        
        // Translating:
        //
        // | 0  0  dx |
        // | 0  0  dy |
        // | 0  0  1  |
        //
        
        // Scaling:
        //
        // | sx 0  0 |
        // | 0  sy 0 |
        // | 0  0  1 |
        //
        
        // Rotation:
        //
        // | cos(a)  sin(a)  0 |
        // | -sin(a) cos(a)  0 |
        // |   0       0     1 |
        
        if(scale != .unit) {
            
            let cScale =
                Vector2.NativeCMatrixType(columns:
                    (Vector2.HomogenousVectorType(scale.theVector.x, 0, 0),
                     Vector2.HomogenousVectorType(0, scale.theVector.y, 0),
                     Vector2.HomogenousVectorType(0, 0, 1)))
            
            matrix *= Vector2.NativeMatrixType(cScale)
        }
        
        if(angle != 0) {
            let c = cos(-angle)
            let s = sin(-angle)
            
            let cRotation =
                Vector2.NativeCMatrixType(columns:
                    (Vector2.HomogenousVectorType(c, s, 0),
                     Vector2.HomogenousVectorType(-s, c, 0),
                     Vector2.HomogenousVectorType(0, 0, 1)))
            
            matrix *= Vector2.NativeMatrixType(cRotation)
        }
        
        if(translate != .zero) {
            let cTranslation =
                Vector2.NativeCMatrixType(columns:
                    (Vector2.HomogenousVectorType(1, 0, translate.theVector.x),
                     Vector2.HomogenousVectorType(0, 1, translate.theVector.y),
                     Vector2.HomogenousVectorType(0, 0, 1)))
            
            matrix *= Vector2.NativeMatrixType(cTranslation)
        }
        
        return matrix
    }
    
    // Matrix multiplication
    static public func *(lhs: Vector2, rhs: Vector2.NativeMatrixType) -> Vector2 {
        let homog = Vector2.HomogenousVectorType(lhs.theVector.x, lhs.theVector.y, 1)
        
        let transformed = homog * rhs
        
        return Vector2(x: transformed.x, y: transformed.y)
    }
}

// MARK: Rotation
extension Vector2 {
    /// Returns a rotated version of this vector, rotated around by a given 
    /// angle in radians
    public func rotated(by angleInRadians: JFloat) -> Vector2 {
        return Vector2.rotate(self, by: angleInRadians)
    }
    
    /// Rotates this vector around by a given angle in radians
    public mutating func rotate(by angleInRadians: JFloat) -> Vector2 {
        self = rotated(by: angleInRadians)
        return self
    }
    
    /// Rotates a given vector by an angle in radians
    public static func rotate(_ vec: Vector2, by angleInRadians: JFloat) -> Vector2 {
        
        // Check if we have a 0º or 180º rotation - these we can figure out
        // using conditionals to speedup common paths.
        let remainder =
            angleInRadians.truncatingRemainder(dividingBy: .pi * 2)
        
        if(remainder == 0) {
            return vec
        }
        if(remainder == .pi) {
            return -vec
        }
        
        let c = cos(angleInRadians)
        let s = sin(angleInRadians)
        
        return Vector2(x: (c * vec.x) - (s * vec.y), y: (c * vec.y) + (s * vec.x))
    }
}

extension Collection where Iterator.Element: VectorRepresentable, IndexDistance == Int {
    /// Averages this collection of vectors into one Vector2 point
    public func averageVector() -> Vector2 {
        var average = Vector2.zero
        
        for vec in self {
            average += vec.vector
        }
        
        return average / JFloat(count)
    }
}

/// Returns a Vector2 that represents the minimum coordinates between two 
/// Vector2 objects
@_transparent
public func min(_ a: Vector2, _ b: Vector2) -> Vector2 {
    return Vector2(min(a.theVector, b.theVector))
}

/// Returns a Vector2 that represents the maximum coordinates between two 
/// Vector2 objects
@_transparent
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

// This • character is available as 'Option-8' combination on Mac keyboards
infix operator • : MultiplicationPrecedence
infix operator =/ : MultiplicationPrecedence

public func round(_ x: Vector2) -> Vector2 {
    return Vector2(x: round(x.x), y: round(x.y))
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
