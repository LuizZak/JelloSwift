//
//  ClosedShape.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Contains a set of points that is equivalent as the internal shape of a sofy body
public struct ClosedShape: ExpressibleByArrayLiteral
{
    public typealias Element = Vector2
    
    fileprivate(set) public var localVertices: [Vector2] = []
    
    /// Returns the Vector2 for the vertex with a given integer index on this ClosedShape
    public subscript(i: Int) -> Vector2 { return localVertices[i] }
    
    public init(arrayLiteral elements: ClosedShape.Element...)
    {
        localVertices = elements
    }
    
    /// Start adding vertices to this closed shape.
    /// Calling this method will erase any existing verts
    public mutating func begin()
    {
        localVertices = []
    }
    
    /// Adds a vertex to this closed shape
    public mutating func addVertex(_ vertex: Vector2)
    {
        localVertices += vertex
    }
    
    /// Adds a vertex to this closed shape
    public mutating func addVertex(x: CGFloat, y: CGFloat)
    {
        addVertex(Vector2(x, y))
    }
    
    /// Finishes constructing this closed shape, and convert them to local space (by default)
    public mutating func finish(_ recenter: Bool = true)
    {
        if(recenter)
        {
            // Find the average location of all the vertices
            let center = averageVectors(localVertices)
            
            localVertices = localVertices.map { $0 - center }
        }
    }
    
    /// Transforms all vertices by the given angle and scale locally
    public mutating func transformOwn(_ angleInRadians: CGFloat, localScale: Vector2)
    {
        localVertices = localVertices.map { transform(vertex: $0, worldPos: Vector2.zero, angleInRadians: angleInRadians, localScale: localScale) }
    }
    
    /// Gets a new list of vertices, transformed by the given position, angle, and scale.
    /// transformation is applied in the following order:  scale -> rotation -> position.
    
    public func transformVertices(_ worldPos: Vector2, angleInRadians: CGFloat, localScale: Vector2 = Vector2.unit) -> [Vector2]
    {
        return localVertices.map { transform(vertex: $0, worldPos: worldPos, angleInRadians: angleInRadians, localScale: localScale) }
    }
    
    /// Transforms the points on this closed shape into the given array of points.
    /// Transformation is applied in the following order:  scale -> rotation -> position.
    /// - note: The target array of points must have the **same** count of vertices as this closed shape.
    public func transformVertices(_ target: inout [Vector2], worldPos: Vector2, angleInRadians: CGFloat, localScale: Vector2 = Vector2.unit)
    {
        for i in 0..<(min(target.count, localVertices.count))
        {
            target[i] = transform(vertex: localVertices[i], worldPos: worldPos, angleInRadians: angleInRadians, localScale: localScale)
        }
    }
    
    private func transform(vertex: Vector2, worldPos: Vector2, angleInRadians: CGFloat, localScale: Vector2) -> Vector2
    {
        return rotateVector(vertex * localScale, angleInRadians: angleInRadians) + worldPos
    }
}
