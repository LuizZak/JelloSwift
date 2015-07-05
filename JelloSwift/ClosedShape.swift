//
//  ClosedShape.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Contains a set of points that is equivalent as the internal shape of a sofy body
public struct ClosedShape
{
    public var localVertices: [Vector2] = []
    
    /// Returns the Vector2 for the vertex with a given integer index on this ClosedShape
    public subscript(i: Int) -> Vector2 { return localVertices[i] }
    
    /// Start adding vertices to this closed shape.
    /// Calling this method will erase any existing verts
    public mutating func begin()
    {
        localVertices = []
    }
    
    /// Adds a vertex to this closed shape
    public mutating func addVertex(vertex: Vector2)
    {
        localVertices += vertex
    }
    
    /// Adds a vertex to this closed shape
    public mutating func addVertex(x x: CGFloat, y: CGFloat)
    {
        addVertex(Vector2(x, y))
    }
    
    /// Finishes constructing this closed shape, and convert them to local space (by default)
    public mutating func finish(recenter: Bool = true)
    {
        if(recenter)
        {
            // Find the average location of all the vertices
            let center = averageVectors(localVertices)
            
            localVertices = localVertices.map { $0 - center }
        }
    }
    
    /// Transforms all vertices by the given angle and scale
    public mutating func transformOwn(angleInRadians: CGFloat, localScale: Vector2)
    {
        localVertices = localVertices.map { rotateVector($0 * localScale, angleInRadians: angleInRadians) }
    }
    
    /// Gets a new list of vertices, transformed by the given position, angle, and scale.
    /// transformation is applied in the following order:  scale -> rotation -> position.
    public func transformVertices(worldPos: Vector2, angleInRadians: CGFloat, localScale: Vector2 = Vector2.One) -> [Vector2]
    {
        return localVertices.map { rotateVector($0 * localScale, angleInRadians: angleInRadians) + worldPos }
    }
    
    /// Transforms the points on this closed shape into the given array of points.
    /// The array of points must have the same count of vertices as this closed shape
    /// transformation is applied in the following order:  scale -> rotation -> position.
    public func transformVertices(inout target:[Vector2], worldPos: Vector2, angleInRadians: CGFloat, localScale: Vector2 = Vector2.One)
    {
        target = transformVertices(worldPos, angleInRadians: angleInRadians, localScale: localScale)
    }
}