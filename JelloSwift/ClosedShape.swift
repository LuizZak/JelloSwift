//
//  ClosedShape.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Contains a set of points that is equivalent as the internal shape of a sofy body
class ClosedShape: NSObject
{
    var localVertices: [Vector2] = [];
    
    override init()
    {
        super.init();
    }
    
    // Start adding vertices to this closed shape.
    // Calling this method will erase any existing verts
    func begin()
    {
        localVertices = [];
    }
    
    // Adds a vertex to this closed shape
    func addVertex(vertex: Vector2)
    {
        localVertices += vertex;
    }
    
    // Finishes constructing this closed shape, and convert them to local space (by default)
    func finish(recenter: Bool = true)
    {
        if(recenter)
        {
            // Find the average location of all the vertices
            var center = Vector2();
            for vertex in localVertices
            {
                center += vertex;
            }
            
            center /= localVertices.count;
            
            // Subtract the center from all the elements
            for i in 0..<localVertices.count
            {
                localVertices[i] -= center;
            }
        }
    }
    
    // Transforms all vertices by the given angle and scale
    func transformOwn(angleInRadians: CGFloat, localScale: Vector2)
    {
        for i in 0..<localVertices.count
        {
            localVertices[i] *= localScale;
            localVertices[i] = rotateVector(localVertices[i], angleInRadians);
        }
    }
    
    /// Gets a new list of vertices, transformed by the given position, angle, and scale.
    /// transformation is applied in the following order:  scale -> rotation -> position.
    func transformVertices(worldPos: Vector2, angleInRadians: CGFloat, localScale: Vector2 = Vector2(1, 1)) -> [Vector2]
    {
        var ret: [Vector2] = [Vector2](count: localVertices.count, repeatedValue: Vector2());
        var i = 0;
        
        for vertex in localVertices
        {
            var v = rotateVector(vertex * localScale, angleInRadians) + worldPos;
            ret[i++] = v;
        }
        
        return ret;
    }
    
    /// Transforms the points on this closed shape into the given array of points.
    /// The array of points must have the same count of vertices as this closed shape
    /// transformation is applied in the following order:  scale -> rotation -> position.
    func transformVertices(inout target:[Vector2], worldPos: Vector2, angleInRadians: CGFloat, localScale: Vector2 = Vector2(1, 1))
    {
        var i = 0;
        for vertex in localVertices
        {
            target[i++] = rotateVector(vertex * localScale, angleInRadians) + worldPos;
        }
    }
}