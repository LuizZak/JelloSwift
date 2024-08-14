import Foundation

/// Represents a 2D vector
public struct Vector3: Equatable, CustomStringConvertible, Codable {

    /// A zeroed-value Vector3
    public static let zero: Self = Vector3(x: 0, y: 0, z: 0)

    /// An unit-valued Vector3
    public static let unit: Self = Vector3(x: 1, y: 1, z: 1)

    /// An unit-valued Vector3.
    /// Alias for 'unit'.
    public static let one = unit

    /// The JFloat representation of this vector's x axis
    public var x: JFloat

    /// The JFloat representation of this vector's y axis
    public var y: JFloat

    /// The JFloat representation of this vector's z axis
    public var z: JFloat

    /// Returns the squared length of this Vector3
    @inlinable
    public var length: JFloat {
        return x * x + y * y + z * z
    }

    /// Returns the magnitude (or square root of the squared length) of this
    /// Vector3
    @inlinable
    public var magnitude: JFloat {
        return sqrt(length)
    }

    /// For conformance to VectorRepresentable - always returns self
    @inlinable
    public var vector: Vector3 {
        return self
    }

    /// Textual representation of this vector's coordinates
    public var description: String {
        return "Vector3(x: \(self.x), y: \(self.y), z: \(self.z))"
    }

    /// Inits a 0-valued Vector3
    @inlinable
    public init() {
        x = 0
        y = 0
        z = 0
    }

    /// Inits a vector 3 with three integer components
    @inlinable
    public init(x: Int, y: Int, z: Int) {
        self.x = JFloat(x)
        self.y = JFloat(y)
        self.z = JFloat(z)
    }

    /// Inits a vector 3 with three float components
    @inlinable
    public init(x: Float, y: Float, z: Float) {
        self.x = JFloat(x)
        self.y = JFloat(y)
        self.z = JFloat(z)
    }

    /// Inits a vector 3 with two double-precision floating point components
    @inlinable
    public init(x: Double, y: Double, z: Double) {
        self.x = JFloat(x)
        self.y = JFloat(y)
        self.z = JFloat(z)
    }

    /// Inits a vector 3 with X, Y, and Z defined as a given float
    @inlinable
    public init(value: JFloat) {
        x = value
        y = value
        z = value
    }

    /// Inits a vector 3 with the X, and Y components of a given vector 2, and
    /// the specified value for the Z component.
    @inlinable
    public init(_ vec: Vector2, z: JFloat) {
        (self.x, self.y) = (vec.x, vec.y)
        self.z = z
    }

    /// Inits a vector 3 with X, Y, and Z defined as a given tuple
    @inlinable
    public init(_ value: (JFloat, JFloat, JFloat)) {
        (x, y, z) = value
    }

    /// Returns the distance between this Vector3 and another Vector3
    @inlinable
    public func distance(to vec: Vector3) -> JFloat {
        let d = self - vec

        return d.magnitude
    }

    /// Returns the distance squared between this Vector3 and another Vector3
    @inlinable
    public func distanceSquared(to vec: Vector3) -> JFloat {
        let d = self - vec

        return d.length
    }

    // Normalizes this Vector3 instance.
    // This alters the current vector instance
    @inlinable
    public mutating func normalize() -> Vector3 {
        self = normalized()
        return self
    }

    /// Returns a normalized version of this Vector3
    @inlinable
    public func normalized() -> Vector3 {
        let l = magnitude

        return Vector3(x: x / l, y: y / l, z: z / l)
    }
}

/// Dot and Cross products
extension Vector3 {
    /// Calculates the dot product between this and another provided Vector3
    @inlinable
    public func dot(_ other: Vector3) -> JFloat {
        return (x * other.x) + (y * other.y) + (z * other.z)
    }

    /// Calculates the cross product between this and another provided Vector3..
    @inlinable
    public func cross(_ other: Vector3) -> Vector3 {
        let cx = y * other.y - z * other.z
        let cy = z * other.z - x * other.x
        let cz = x * other.x - y * other.y

        return Vector3(x: cx, y: cy, z: cz)
    }
}

// MARK: Operators
extension Vector3 {
    ////
    // Comparison operators
    ////
    @inlinable
    static public func == (lhs: Vector3, rhs: Vector3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }

    /// Compares two vectors and returns if `lhs` is greater than `rhs`.
    ///
    /// Performs `lhs.x > rhs.x && lhs.y > rhs.y && lhs.z > rhs.z`
    @inlinable
    static public func > (lhs: Vector3, rhs: Vector3) -> Bool {
        return lhs.x > rhs.x && lhs.y > rhs.y && lhs.z > rhs.z
    }

    /// Compares two vectors and returns if `lhs` is greater than or equal to
    /// `rhs`.
    ///
    /// Performs `lhs.x >= rhs.x && lhs.y >= rhs.y && lhs.z >= rhs.z`
    @inlinable
    static public func >= (lhs: Vector3, rhs: Vector3) -> Bool {
        return lhs.x >= rhs.x && lhs.y >= rhs.y && lhs.z >= rhs.z
    }

    /// Compares two vectors and returns if `lhs` is less than `rhs`.
    ///
    /// Performs `lhs.x < rhs.x && lhs.y < rhs.y && lhs.z < rhs.z`
    @inlinable
    static public func < (lhs: Vector3, rhs: Vector3) -> Bool {
        return lhs.x < rhs.x && lhs.y < rhs.y && lhs.z < rhs.z
    }

    /// Compares two vectors and returns if `lhs` is less than or equal to `rhs`.
    ///
    /// Performs `lhs.x <= rhs.x && lhs.y <= rhs.y && lhs.z <= rhs.z`
    @inlinable
    static public func <= (lhs: Vector3, rhs: Vector3) -> Bool {
        return lhs.x <= rhs.x && lhs.y <= rhs.y && lhs.z <= rhs.z
    }

    // Unary operators
    @inlinable
    static public prefix func - (lhs: Vector3) -> Vector3 {
        return Vector3(x: -lhs.x, y: -lhs.y, z: -lhs.z)
    }

    // DOT operator
    /// Calculates the dot product between two provided coordinates.
    /// See `Vector3.dot`
    @inlinable
    static public func • (lhs: Vector3, rhs: Vector3) -> JFloat {
        return lhs.dot(rhs)
    }

    // CROSS operator
    /// Calculates the dot product between two provided coordinates
    /// See `Vector3.cross`
    @inlinable
    static public func =/ (lhs: Vector3, rhs: Vector3) -> Vector3 {
        return lhs.cross(rhs)
    }

    ////
    // Basic arithmetic operators
    ////
    @inlinable
    static public func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }

    @inlinable
    static public func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    @inlinable
    static public func * (lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x * rhs.x, y: lhs.y * rhs.y, z: lhs.z * rhs.z)
    }

    @inlinable
    static public func / (lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs.x / rhs.x, y: lhs.y / rhs.y, z: lhs.z / rhs.z)
    }

    @inlinable
    static public func % (lhs: Vector3, rhs: Vector3) -> Vector3 {
        return Vector3(
            x: lhs.x.truncatingRemainder(dividingBy: rhs.x),
            y: lhs.y.truncatingRemainder(dividingBy: rhs.y),
            z: lhs.z.truncatingRemainder(dividingBy: rhs.z)
        )
    }

    // JFloat interaction
    @inlinable
    static public func + (lhs: Vector3, rhs: JFloat) -> Vector3 {
        return Vector3(x: lhs.x + rhs, y: lhs.y + rhs, z: lhs.z + rhs)
    }

    @inlinable
    static public func - (lhs: Vector3, rhs: JFloat) -> Vector3 {
        return Vector3(x: lhs.x - rhs, y: lhs.y - rhs, z: lhs.z - rhs)
    }

    @inlinable
    static public func * (lhs: Vector3, rhs: JFloat) -> Vector3 {
        return Vector3(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }

    @inlinable
    static public func / (lhs: Vector3, rhs: JFloat) -> Vector3 {
        return Vector3(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
    }

    @inlinable
    static public func % (lhs: Vector3, rhs: JFloat) -> Vector3 {
        return Vector3(
            x: lhs.x.truncatingRemainder(dividingBy: rhs),
            y: lhs.y.truncatingRemainder(dividingBy: rhs),
            z: lhs.z.truncatingRemainder(dividingBy: rhs)
        )
    }

    @inlinable
    static public func / (lhs: JFloat, rhs: Vector3) -> Vector3 {
        return Vector3(x: lhs / rhs.x, y: lhs / rhs.y, z: lhs / rhs.z)
    }

    ////
    // Compound assignment operators
    ////
    @inlinable
    static public func += (lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs + rhs
    }
    @inlinable
    static public func -= (lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs - rhs
    }
    @inlinable
    static public func *= (lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs * rhs
    }
    @inlinable
    static public func /= (lhs: inout Vector3, rhs: Vector3) {
        lhs = lhs / rhs
    }

    // JFloat interaction
    @inlinable
    static public func += (lhs: inout Vector3, rhs: JFloat) {
        lhs = lhs + rhs
    }
    @inlinable
    static public func -= (lhs: inout Vector3, rhs: JFloat) {
        lhs = lhs - rhs
    }
    @inlinable
    static public func *= (lhs: inout Vector3, rhs: JFloat) {
        lhs = lhs * rhs
    }
    @inlinable
    static public func /= (lhs: inout Vector3, rhs: JFloat) {
        lhs = lhs / rhs
    }
}

// MARK: Misc math
extension Vector3 {

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
    public func ratio(_ ratio: JFloat, to other: Vector3) -> Vector3 {
        return self + (other - self) * ratio
    }
}

extension Collection where Iterator.Element == Vector3 {
    /// Averages this collection of vectors into one Vector point as the mean
    /// location of each vector.
    ///
    /// Returns a zero Vector, if the collection is empty.
    @inlinable
    public func averageVector() -> Vector3 {
        if isEmpty {
            return .zero
        }

        return reduce(into: .zero) { $0 += $1 } / JFloat(count)
    }
}

/// Returns a Vector3 that represents the minimum coordinates between two
/// Vector3 objects
@inlinable
public func min(_ a: Vector3, _ b: Vector3) -> Vector3 {
    let x = min(a.x, b.x)
    let y = min(a.y, b.y)
    let z = min(a.z, b.z)

    return Vector3(x: x, y: y, z: z)
}

/// Returns a Vector3 that represents the maximum coordinates between two
/// Vector3 objects
@inlinable
public func max(_ a: Vector3, _ b: Vector3) -> Vector3 {
    let x = max(a.x, b.x)
    let y = max(a.y, b.y)
    let z = max(a.z, b.z)

    return Vector3(x: x, y: y, z: z)
}

////////
//// Define the operations to be performed on the Vector3
////////

@inlinable
public func round(_ x: Vector3) -> Vector3 {
    return Vector3(x: round(x.x), y: round(x.y), z: round(x.z))
}

@inlinable
public func ceil(_ x: Vector3) -> Vector3 {
    return Vector3(x: ceil(x.x), y: ceil(x.y), z: ceil(x.z))
}

@inlinable
public func floor(_ x: Vector3) -> Vector3 {
    return Vector3(x: floor(x.x), y: floor(x.y), z: floor(x.z))
}

@inlinable
public func abs(_ x: Vector3) -> Vector3 {
    return Vector3(x: abs(x.x), y: abs(x.y), z: abs(x.z))
}
