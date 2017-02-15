//
//  ClosedShape.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Contains a set of points that is equivalent as the internal shape of a soft body.
/// Do note that points must be added in a counter-clockwise fashion, since the points
/// are represented in an Euclidean space where the y-axis grows upwards, as oposed to
/// screen space where the y-axis grows down.
public struct ClosedShape: ExpressibleByArrayLiteral {
    public typealias Element = Vector2
    
    fileprivate(set) public var localVertices: [Vector2] = []
    
    /// Gets or sets the Vector2 for the vertex with a given integer index on this ClosedShape
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
    public mutating func addVertex(x: CGFloat, y: CGFloat) {
        addVertex(Vector2(x, y))
    }
    
    /// Finishes constructing this closed shape, optionally converting them to local space (by default)
    public mutating func finish(recentering recenter: Bool = true) {
        if(recenter) {
            self.recenter()
        }
    }
    
    /// Returns a closed shape that is this closed shape, with the closed shape's centroid
    /// (geometric center) laying on (0, 0).
    public func centered() -> ClosedShape {
        // Find the average location of all the vertices
        let center = localVertices.averageVector()
        
        return ClosedShape(points: localVertices.map { $0 - center })
    }
    
    /// Recenters the points of this closed shape so its centroid (geometric center) lays
    /// on (0, 0).
    public mutating func recenter() {
        self = centered()
    }
}

/// MARK: - Shape transformations
extension ClosedShape {
    
    /// Transforms all vertices by the given angle and scale locally
    public mutating func transformOwnBy(rotatingBy angleInRadians: CGFloat = 0, scalingBy scale: Vector2 = .unit) {
        localVertices = localVertices.map { transform(vertex: $0, worldPos: Vector2.zero, angleInRadians: angleInRadians, localScale: scale) }
    }
    
    /// Gets a new closed shape from this shape transformed by the given position, angle, and scale.
    /// transformation is applied in the following order:  scale -> rotation -> position.
    public func transformedBy(translatingBy worldPos: Vector2 = .zero, rotatingBy angleInRadians: CGFloat = 0, scalingBy localScale: Vector2 = .unit) -> ClosedShape {
        return ClosedShape(points: localVertices.map { transform(vertex: $0, worldPos: worldPos, angleInRadians: angleInRadians, localScale: localScale) })
    }
    
    /// Transforms the points on this closed shape into the given array of points.
    /// Transformation is applied in the following order:  scale -> rotation -> position.
    /// - note: The target array of points must have the **same** count of vertices as this closed shape.
    public func transformVertices(_ target: inout [Vector2], worldPos: Vector2, angleInRadians: CGFloat, localScale: Vector2 = Vector2.unit) {
        for i in 0..<target.count {
            target[i] = transform(vertex: localVertices[i], worldPos: worldPos, angleInRadians: angleInRadians, localScale: localScale)
        }
    }
    
    private func transform(vertex: Vector2, worldPos: Vector2, angleInRadians: CGFloat, localScale: Vector2) -> Vector2 {
        return Vector2.rotate(vertex * localScale, by: angleInRadians) + worldPos
    }
}

/// MARK: - Shape creation methods
extension ClosedShape {
    
    /// Creates a closed shape that represents a circle of a given radius, with the specified number of points
    /// around its circumference
    public static func circle(ofRadius radius: CGFloat, pointCount: Int) -> ClosedShape {
        
        var shape = ClosedShape()
        shape.begin()
        for i in 0..<pointCount
        {
            let n = PI * 2 * (CGFloat(i) / CGFloat(pointCount))
            shape.addVertex(Vector2(cos(-n) * radius, sin(-n) * radius))
        }
        shape.finish()
        
        return shape
    }
    
    /// Creates a closed shape that represents a square, with side of the specified length
    public static func square(ofSide length: CGFloat) -> ClosedShape {
        return rectangle(ofSize: Vector2(value: length))
    }
    
    /// Creates a closed shape that represents a rectangle, with side of the specified length
    public static func rectangle(ofSize size: Vector2) -> ClosedShape {
        // Counter-clockwise!
        var shape = ClosedShape()
        shape.begin()
        shape.addVertex(Vector2(-size.x,  size.y))
        shape.addVertex(Vector2( size.x,  size.y))
        shape.addVertex(Vector2( size.x, -size.y))
        shape.addVertex(Vector2(-size.x, -size.y))
        shape.finish()
        
        return shape
    }
}
