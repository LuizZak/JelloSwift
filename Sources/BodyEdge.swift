//
//  BodyEdge.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 05/04/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Contains information about the edge of a body
public struct BodyEdge: Codable {
    
    /// The index of the edge on the body
    public var edgeIndex = 0
    
    /// Index of the start point mass of this edge on the body's `pointMasses`
    /// array
    public var startPointIndex: Int
    
    /// Index of the end point mass of this edge on the body's `pointMasses`
    /// array
    public var endPointIndex: Int
    
    /// The start position of the edge
    public var start = Vector2.zero
    
    /// The end position of the edge
    public var end = Vector2.zero
    
    /// The normal for the edge
    public var normal = Vector2.zero
    
    /// The difference between the start and end points, normalized
    public var difference = Vector2.zero
    
    /// The edge's length
    public var length: JFloat = 0
    
    /// The edge's length, squared
    public var lengthSquared: JFloat = 0
    
    public init() {
        startPointIndex = 0
        endPointIndex = 0
    }
    
    /// Initializes an edge with a given index, and start and end vectors.
    /// The `difference`, `normal`, `length` and `lengthSquared` properties are
    /// automatically initialized out of these values.
    public init(edgeIndex: Int, startPointIndex: Int, endPointIndex: Int, start: Vector2, end: Vector2) {
        self.edgeIndex = edgeIndex
        self.startPointIndex = startPointIndex
        self.endPointIndex = endPointIndex
        self.start = start
        self.end = end
        
        difference = (end - start).normalized()
        
        normal = difference.perpendicular()
        
        length = start.distance(to: end)
        lengthSquared = length * length
    }
}
