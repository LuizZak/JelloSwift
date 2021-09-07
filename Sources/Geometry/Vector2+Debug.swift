//
//  Vector2.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import simd

// TODO: Once Swift gets inlining SIMD in debug mode, remove this stopgap
// implementation

#if DEBUG

/// Represents a 2D vector
public struct Vector2: VectorRepresentable, Equatable, CustomStringConvertible, Codable {
    
    /// A zeroed-value Vector2
    public static let zero = Vector2(x: 0, y: 0)
    
    /// An unit-valued Vector2
    public static let unit = Vector2(x: 1, y: 1)
    
    /// An unit-valued Vector2.
    /// Aliast for 'unit'.
    public static let one = unit
    
    #if arch(x86_64) || arch(arm64)
    /// Used to match `JFloat`'s native type
    public typealias NativeVectorType = SIMD2<Double>
    
    /// The 3x3 matrix type that can be used to apply transformations by
    /// multiplying on this Vector2
    public typealias NativeMatrixType = double3x3
    
    /// This is used during affine transformation
    public typealias HomogenousVectorType = SIMD3<Double>
    #elseif arch(i386) || arch(arm)
    ///Used to match `JFloat`'s native type
    public typealias NativeVectorType = SIMD2<Float>
    
    /// The 3x3 matrix type that can be used to apply transformations by
    /// multiplying on this Vector2
    public typealias NativeMatrixType = float3x3
    
    /// This is used during affine transformation
    public typealias HomogenousVectorType = SIMD3<Float>
    #endif
    
    @usableFromInline
    var theVector: NativeVectorType {
        return NativeVectorType(x, y)
    }
    
    /// The JFloat representation of this vector's x axis
    public var x: JFloat
    
    /// The JFloat representation of this vector's y axis
    public var y: JFloat
    
    /// Returns the angle in radians of this Vector2
    @inlinable
    public var angle: JFloat {
        return atan2(y, x)
    }
    
    /// Returns the squared length of this Vector2
    @inlinable
    public var length: JFloat {
        return x * x + y * y
    }
    
    /// Returns the magnitude (or square root of the squared length) of this
    /// Vector2
    @inlinable
    public var magnitude: JFloat {
        return sqrt(length)
    }
    
    /// For conformance to VectorRepresentable - always returns self
    @inlinable
    public var vector: Vector2 {
        return self
    }
    
    /// Textual representation of this vector's coordinates
    public var description: String {
        return "{ \(self.x) : \(self.y) }"
    }
    
    @inlinable
    init(_ vector: NativeVectorType) {
        x = vector.x
        y = vector.y
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.init(try container.decode(NativeVectorType.self, forKey: .theVector))
    }
    
    /// Inits a 0-valued Vector2
    @inlinable
    public init() {
        x = 0
        y = 0
    }
    
    /// Inits a vector 2 with two integer components
    @inlinable
    public init(x: Int, y: Int) {
        self.x = JFloat(x)
        self.y = JFloat(y)
    }
    
    /// Inits a vector 2 with two float components
    @inlinable
    public init(x: Float, y: Float) {
        self.x = JFloat(x)
        self.y = JFloat(y)
    }
    
    /// Inits a vector 2 with two double-precision floating point components
    @inlinable
    public init(x: Double, y: Double) {
        self.x = JFloat(x)
        self.y = JFloat(y)
    }
    
    /// Inits a vector 2 with X and Y defined as a given float
    @inlinable
    public init(value: JFloat) {
        x = value
        y = value
    }
    
    /// Returns the distance between this Vector2 and another Vector2
    @inlinable
    public func distance(to vec: Vector2) -> JFloat {
        let d = self - vec
        
        return d.magnitude
    }
    
    /// Returns the distance squared between this Vector2 and another Vector2
    @inlinable
    public func distanceSquared(to vec: Vector2) -> JFloat {
        let d = self - vec
        
        return d.length
    }
    
    /// Makes this Vector2 perpendicular to its current position.
    /// This alters the vector instance
    @inlinable
    public mutating func formPerpendicular() -> Vector2 {
        self = perpendicular()
        return self
    }
    
    /// Returns a Vector2 perpendicular to this Vector2
    @inlinable
    public func perpendicular() -> Vector2 {
        return Vector2(x: -y, y: x)
    }
    
    // Normalizes this Vector2 instance.
    // This alters the current vector instance
    @inlinable
    public mutating func normalize() -> Vector2 {
        self = normalized()
        return self
    }
    
    /// Returns a normalized version of this Vector2
    @inlinable
    public func normalized() -> Vector2 {
        let l = magnitude
        
        return Vector2(x: x / l, y: y / l)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(theVector, forKey: .theVector)
    }
    
    private enum CodingKeys: String, CodingKey {
        case theVector
    }
}

/// Dot and Cross products
extension Vector2 {
    /// Calculates the dot product between this and another provided Vector2
    @inlinable
    public func dot(_ other: Vector2) -> JFloat {
        return (x * other.x) + (y * other.y)
    }
    
    /// Calculates the cross product between this and another provided Vector2.
    /// The resulting scalar would match the 'z' axis of the cross product
    /// between 3d vectors matching the x and y coordinates of the operands, with
    /// the 'z' coordinate being 0.
    @inlinable
    public func cross(_ other: Vector2) -> JFloat {
        return (x * other.y) - (other.x * y)
    }
}

// MARK: Operators
extension Vector2 {
    ////
    // Comparision operators
    ////
    @inlinable
    static public func ==(lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    /// Compares two vectors and returns if `lhs` is greater than `rhs`.
    ///
    /// Performs `lhs.x > rhs.x && lhs.y > rhs.y`
    @inlinable
    static public func >(lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.x > rhs.x && lhs.y > rhs.y
    }
    
    /// Compares two vectors and returns if `lhs` is greater than or equal to
    /// `rhs`.
    ///
    /// Performs `lhs.x >= rhs.x && lhs.y >= rhs.y`
    @inlinable
    static public func >=(lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.x >= rhs.x && lhs.y >= rhs.y
    }
    
    /// Compares two vectors and returns if `lhs` is less than `rhs`.
    ///
    /// Performs `lhs.x < rhs.x && lhs.y < rhs.y`
    @inlinable
    static public func <(lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.x < rhs.x && lhs.y < rhs.y
    }
    
    /// Compares two vectors and returns if `lhs` is less than or equal to `rhs`.
    ///
    /// Performs `lhs.x <= rhs.x && lhs.y <= rhs.y`
    @inlinable
    static public func <=(lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.x <= rhs.x && lhs.y <= rhs.y
    }
    
    // Unary operators
    @inlinable
    static public prefix func -(lhs: Vector2) -> Vector2 {
        return Vector2(x: -lhs.x, y: -lhs.y)
    }
    
    // DOT operator
    /// Calculates the dot product between two provided coordinates.
    /// See `Vector2.dot`
    @inlinable
    static public func •(lhs: Vector2, rhs: Vector2) -> JFloat {
        return lhs.dot(rhs)
    }
    
    // CROSS operator
    /// Calculates the dot product between two provided coordinates
    /// See `Vector2.cross`
    @inlinable
    static public func =/(lhs: Vector2, rhs: Vector2) -> JFloat {
        return lhs.cross(rhs)
    }
    
    ////
    // Basic arithmetic operators
    ////
    @inlinable
    static public func +(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    @inlinable
    static public func -(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    @inlinable
    static public func *(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }
    
    @inlinable
    static public func /(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
    }
    
    @inlinable
    static public func %(lhs: Vector2, rhs: Vector2) -> Vector2 {
        return Vector2(x: lhs.x.truncatingRemainder(dividingBy: rhs.x),
                       y: lhs.y.truncatingRemainder(dividingBy: rhs.y))
    }
    
    // JFloat interaction
    @inlinable
    static public func +(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(x: lhs.x - rhs, y: lhs.y - rhs)
    }
    
    @inlinable
    static public func -(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(x: lhs.x - rhs, y: lhs.y - rhs)
    }
    
    @inlinable
    static public func *(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    @inlinable
    static public func /(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    @inlinable
    static public func %(lhs: Vector2, rhs: JFloat) -> Vector2 {
        return Vector2(x: lhs.x.truncatingRemainder(dividingBy: rhs),
                       y: lhs.y.truncatingRemainder(dividingBy: rhs))
    }
    
    @inlinable
    static public func /(lhs: JFloat, rhs: Vector2) -> Vector2 {
        return Vector2(x: lhs / rhs.x, y: lhs / rhs.y)
    }
    
    ////
    // Compound assignment operators
    ////
    @inlinable
    static public func +=(lhs: inout Vector2, rhs: Vector2) {
        lhs = lhs + rhs
    }
    @inlinable
    static public func -=(lhs: inout Vector2, rhs: Vector2) {
        lhs = lhs - rhs
    }
    @inlinable
    static public func *=(lhs: inout Vector2, rhs: Vector2) {
        lhs = lhs * rhs
    }
    @inlinable
    static public func /=(lhs: inout Vector2, rhs: Vector2) {
        lhs = lhs / rhs
    }
    
    // JFloat interaction
    @inlinable
    static public func +=(lhs: inout Vector2, rhs: JFloat) {
        lhs = lhs + rhs
    }
    @inlinable
    static public func -=(lhs: inout Vector2, rhs: JFloat) {
        lhs = lhs - rhs
    }
    @inlinable
    static public func *=(lhs: inout Vector2, rhs: JFloat) {
        lhs = lhs * rhs
    }
    @inlinable
    static public func /=(lhs: inout Vector2, rhs: JFloat) {
        lhs = lhs / rhs
    }
}

@usableFromInline
let _identityMatrix = Vector2.NativeMatrixType(1)

// MARK: Matrix-transformation
extension Vector2 {
    
    /// Creates a matrix that when multiplied with a Vector2 object applies the
    /// given set of transformations.
    ///
    /// If all default values are set, an identity matrix is created, which does
    /// not alter a Vector2's coordinates once applied.
    ///
    /// The order of operations are: scaling -> rotation -> translation
    @inlinable
    static public func matrix(scalingBy scale: Vector2 = Vector2.unit,
                              rotatingBy angle: JFloat = 0,
                              translatingBy translate: Vector2 = Vector2.zero) -> Vector2.NativeMatrixType {
        
        var matrix = _identityMatrix
        
        // Prepare matrices
        
        // Scaling:
        //
        // | sx 0  0 |
        // | 0  sy 0 |
        // | 0  0  1 |
        //
        
        let cScale =
            Vector2.NativeMatrixType(columns:
                (Vector2.HomogenousVectorType(scale.x, 0, 0),
                 Vector2.HomogenousVectorType(0, scale.y, 0),
                 Vector2.HomogenousVectorType(0, 0, 1)))
        
        matrix *= cScale
        
        // Rotation:
        //
        // | cos(a)  sin(a)  0 |
        // | -sin(a) cos(a)  0 |
        // |   0       0     1 |
        
        if angle != 0 {
            let c = cos(-angle)
            let s = sin(-angle)
            
            let cRotation =
                Vector2.NativeMatrixType(columns:
                    (Vector2.HomogenousVectorType(c, s, 0),
                     Vector2.HomogenousVectorType(-s, c, 0),
                     Vector2.HomogenousVectorType(0, 0, 1)))
            
            matrix *= cRotation
        }
        
        // Translation:
        //
        // | 0  0  dx |
        // | 0  0  dy |
        // | 0  0  1  |
        //
        
        let cTranslation =
            Vector2.NativeMatrixType(columns:
                (Vector2.HomogenousVectorType(1, 0, translate.x),
                 Vector2.HomogenousVectorType(0, 1, translate.y),
                 Vector2.HomogenousVectorType(0, 0, 1)))
        
        matrix *= cTranslation
        
        return matrix
    }
    
    // Matrix multiplication
    @inlinable
    static public func *(lhs: Vector2, rhs: Vector2.NativeMatrixType) -> Vector2 {
        let homog = Vector2.HomogenousVectorType(lhs.x, lhs.y, 1)
        
        let transformed = homog * rhs
        
        return Vector2(x: transformed.x, y: transformed.y)
    }
}

// MARK: Rotation
extension Vector2 {
    /// Returns a rotated version of this vector, rotated around by a given
    /// angle in radians
    @inlinable
    public func rotated(by angleInRadians: JFloat) -> Vector2 {
        return Vector2.rotate(self, by: angleInRadians)
    }
    
    /// Rotates this vector around by a given angle in radians
    @inlinable
    public mutating func rotate(by angleInRadians: JFloat) -> Vector2 {
        self = rotated(by: angleInRadians)
        return self
    }
    
    /// Rotates a given vector by an angle in radians
    @inlinable
    public static func rotate(_ vec: Vector2, by angleInRadians: JFloat) -> Vector2 {
        // Check if we have a 0º or 180º rotation - these we can figure out
        // using conditionals to speedup common paths.
        let remainder =
            angleInRadians.truncatingRemainder(dividingBy: .pi * 2)
        
        if remainder == 0 {
            return vec
        }
        if remainder == .pi {
            return -vec
        }
        
        let c = cos(angleInRadians)
        let s = sin(angleInRadians)
        
        return Vector2(x: (c * vec.x) - (s * vec.y),
                       y: (c * vec.y) + (s * vec.x))
    }
}

// MARK: Misc math
extension Vector2 {
    
    /// Returns the vector that lies within this and another vector's ratio line
    /// projected at a specified ratio along the line created by the vectors.
    ///
    /// A vector on ratio of 0 is the same as this vector's position, and 1 is the
    /// same as the other vector's position.
    ///
    /// Values beyond 0 - 1 range project the point across the limits of the line.
    ///
    /// - Parameters:
    ///   - ratio: A ratio (usually 0 through 1) between this and the second vector.
    ///   - other: The second vector to form the line that will have the point
    /// projected onto.
    /// - Returns: A vector that lies within the line created by the two vectors.
    @inlinable
    public func ratio(_ ratio: JFloat, to other: Vector2) -> Vector2 {
        return self + (other - self) * ratio
    }
}

extension Collection where Iterator.Element: VectorRepresentable {
    /// Averages this collection of vectors into one Vector point as the mean
    /// location of each vector.
    ///
    /// Returns a zero Vector, if the collection is empty.
    @inlinable
    public func averageVector() -> Vector2 {
        if isEmpty {
            return .zero
        }
        
        return reduce(into: .zero) { $0 += $1.vector } / JFloat(count)
    }
}

/// Returns a Vector2 that represents the minimum coordinates between two
/// Vector2 objects
@inlinable
public func min(_ a: Vector2, _ b: Vector2) -> Vector2 {
    let x = min(a.x, b.x)
    let y = min(a.y, b.y)
    
    return Vector2(x: x, y: y)
}

/// Returns a Vector2 that represents the maximum coordinates between two
/// Vector2 objects
@inlinable
public func max(_ a: Vector2, _ b: Vector2) -> Vector2 {
    let x = max(a.x, b.x)
    let y = max(a.y, b.y)
    
    return Vector2(x: x, y: y)
}

/// Returns whether rotating from A to B is counter-clockwise
@inlinable
public func vectorsAreCCW(_ A: Vector2, B: Vector2) -> Bool {
    return (B • A.perpendicular()) >= 0.0
}

////////
//// Define the operations to be performed on the Vector2
////////

// This • character is available as 'Option-8' combination on Mac keyboards
infix operator • : MultiplicationPrecedence
infix operator =/ : MultiplicationPrecedence

@inlinable
public func round(_ x: Vector2) -> Vector2 {
    return Vector2(x: round(x.x), y: round(x.y))
}

@inlinable
public func ceil(_ x: Vector2) -> Vector2 {
    return Vector2(x: ceil(x.x), y: ceil(x.y))
}

@inlinable
public func floor(_ x: Vector2) -> Vector2 {
    return Vector2(x: floor(x.x), y: floor(x.y))
}

@inlinable
public func abs(_ x: Vector2) -> Vector2 {
    return Vector2(x: abs(x.x), y: abs(x.y))
}

extension Vector2.NativeMatrixType: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        try self.init([
            container.decode(Vector2.HomogenousVectorType.self),
            container.decode(Vector2.HomogenousVectorType.self),
            container.decode(Vector2.HomogenousVectorType.self)
        ])
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(self.columns.0)
        try container.encode(self.columns.1)
        try container.encode(self.columns.2)
    }
}

#endif
