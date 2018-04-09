//
//  ClosedShape.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

#if os(macOS) || os(iOS)
    import Darwin.C
#elseif os(Linux)
    import Glibc
#endif

/// Contains a set of points that is equivalent as the internal shape of a soft
/// body.
/// Do note that points must be added in a counter-clockwise fashion, since the
/// points are represented in an Euclidean space where the y-axis grows upwards,
/// as oposed to screen space where the y-axis grows down.
public struct ClosedShape: Codable, ExpressibleByArrayLiteral {
    public typealias Element = Vector2
    
    fileprivate(set) public var localVertices: [Vector2] = []
    
    /// Gets or sets the Vector2 for the vertex with a given integer index on
    /// this ClosedShape
    public subscript(i: Int) -> Vector2 {
        get {
            return localVertices[i]
        }
        set {
            localVertices[i] = newValue
        }
    }
    
    public init(arrayLiteral elements: ClosedShape.Element...) {
        localVertices = elements
    }
    
    public init(points: [ClosedShape.Element]) {
        localVertices = points
    }
    
    /// Start adding vertices to this closed shape.
    /// Calling this method will erase any existing verts
    public mutating func begin() {
        localVertices = []
    }
    
    /// Adds a vertex to this closed shape
    public mutating func addVertex(_ vertex: Vector2) {
        localVertices.append(vertex)
    }
    
    /// Adds a vertex to this closed shape
    public mutating func addVertex(x: JFloat, y: JFloat) {
        addVertex(Vector2(x: x, y: y))
    }
    
    /// Finishes constructing this closed shape, optionally converting them to 
    /// local space (by default)
    public mutating func finish(recentering recenter: Bool = true) {
        if recenter {
            self.recenter()
        }
    }
    
    /// Returns a closed shape that is this closed shape, with the closed 
    /// shape's centroid (geometric center) laying on (0, 0).
    public func centered() -> ClosedShape {
        // Find the average location of all the vertices
        let center = localVertices.averageVector()
        
        return ClosedShape(points: localVertices.map { $0 - center })
    }
    
    /// Recenters the points of this closed shape so its centroid (geometric 
    /// center) lays on (0, 0).
    public mutating func recenter() {
        self = centered()
    }
    
    /// Inverts the point list, so they become clockwise if they where counter-
    /// clockwise, or becomes counter-clockwise if they where clockwise.
    public mutating func invertPoints() {
        localVertices = localVertices.reversed()
    }
}

/// MARK: - Shape transformations
extension ClosedShape {
    
    /// Transforms all vertices of this closed shape by the given angle and
    /// scale locally.
    /// Transformation is applied in the following order: scale -> rotation.
    public mutating func transformOwnBy(rotatingBy angleInRadians: JFloat = 0,
                                        scalingBy scale: Vector2 = .unit) {
        
        let m = Vector2.matrix(scalingBy: scale, rotatingBy: angleInRadians)
        
        localVertices = localVertices.map { $0 * m }
    }
    
    /// Gets a new closed shape by taking each point of this closed shape and
    /// multiplying them by the given 2x2 matrix.
    public func transformedBy(multiplyingWith matrix: Vector2.NativeMatrixType) -> ClosedShape {
        let points = localVertices.map {
            $0 * matrix
        }
        
        return ClosedShape(points: points)
    }
    
    /// Gets a new closed shape from this shape transformed by the given
    /// position, angle, and scale.
    /// Transformation is applied in the following order: scale -> rotation ->
    /// position.
    public func transformedBy(translatingBy worldPos: Vector2 = .zero,
                              rotatingBy angleInRadians: JFloat = 0,
                              scalingBy localScale: Vector2 = .unit) -> ClosedShape {
        
        let m = Vector2.matrix(scalingBy: localScale, rotatingBy: angleInRadians, translatingBy: worldPos)
        
        let points = localVertices.map { $0 * m }
        
        return ClosedShape(points: points)
    }
    
    /// Transforms the points on this closed shape, applying the result into a
    /// given array of points.
    /// Transformation is applied in the following order: scale -> rotation ->
    /// position.
    /// - note: The target array of points must have the **same** count of
    ///     vertices as this closed shape.
    public func transformVertices(_ target: inout [Vector2], worldPos: Vector2,
                                  angleInRadians: JFloat,
                                  localScale: Vector2 = Vector2.unit) {
        assert(target.count == localVertices.count)
        
        let m = Vector2.matrix(scalingBy: localScale, rotatingBy: angleInRadians, translatingBy: worldPos)
        
        for i in 0..<target.count {
            target[i] = localVertices[i] * m
        }
    }
    
    /// Transforms the points on this closed shape using a given transformation
    /// matrix, applying the result into a given array of points.
    /// - note: The target array of points must have the **same** count of
    ///     vertices as this closed shape.
    public func transformVertices(_ target: inout [Vector2],
                                  matrix: Vector2.NativeMatrixType) {
        assert(target.count == localVertices.count)
        
        for i in 0..<target.count {
            target[i] = localVertices[i] * matrix
        }
    }
}

extension ClosedShape: RandomAccessCollection, MutableCollection {
    
    public var startIndex: Int {
        return localVertices.startIndex
    }
    public var endIndex: Int {
        return localVertices.endIndex
    }
    
    public func index(after i: Int) -> Int {
        return localVertices.index(after: i)
    }
}

/// MARK: - Shape creation methods
extension ClosedShape {
    
    /// Creates a closed shape that represents a circle of a given radius, with
    /// the specified number of points around its circumference
    public static func circle(ofRadius radius: JFloat, pointCount: Int) -> ClosedShape {
        
        return .create { shape in
            for i in 0..<pointCount
            {
                let n = .pi * 2 * (JFloat(i) / JFloat(pointCount))
                shape.addVertex(Vector2(x: cos(-n) * radius, y: sin(-n) * radius))
            }
        }
    }
    
    /// Creates a closed shape that represents a square, with side of the
    /// specified length
    public static func square(ofSide length: JFloat) -> ClosedShape {
        return rectangle(ofSides: Vector2(value: length))
    }
    
    /// Creates a closed shape that represents a rectangle, with sides of the
    /// specified length
    public static func rectangle(ofSides sides: Vector2) -> ClosedShape {
        
        // Counter-clockwise!
        return .create { shape in
            shape.addVertex(Vector2(x: -sides.x, y:  sides.y) / 2)
            shape.addVertex(Vector2(x:  sides.x, y:  sides.y) / 2)
            shape.addVertex(Vector2(x:  sides.x, y: -sides.y) / 2)
            shape.addVertex(Vector2(x: -sides.x, y: -sides.y) / 2)
        }
    }
    
    /// Creates a closed shape using a closure that passes the closed shape that
    /// is opened and closed automatically once the closure's finished.
    ///
    /// You can specify `centered` to recenter the shape once it's finished
    /// (see `ClosedShape.centered()`).
    public static func create(centered: Bool = true,
                              closure: (inout ClosedShape) -> ()) -> ClosedShape {
        var shape = ClosedShape()
        
        shape.begin()
        closure(&shape)
        shape.finish(recentering: centered)
        
        return shape
    }
}
