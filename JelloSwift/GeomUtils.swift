//
//  GeomUtils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// CGFloat version of the PI constant
public let PI = CGFloat(M_PI)

/// Returns an approximation of the area of the polygon defined by a given set of vertices

public func polygonArea<T: BidirectionalCollection>(_ points: T) -> CGFloat where T.Iterator.Element == Vector2, T.Index: Comparable
{
    if(points.count < 3)
    {
        return 0
    }
    
    var area: CGFloat = 0
    
    if var v2 = points.last
    {
        for p in points
        {
            area += (v2.X + p.X) * (v2.Y - p.Y)
            v2 = p
        }
    }
    
    return area / 2
}

/// Returns an approximation of the area of the polygon defined by a given set of point masses

public func polygonArea<T: Collection>(_ points: T) -> CGFloat where T.Iterator.Element == PointMass
{
    return polygonArea(points.map { $0.position })
}

/// Checks if 2 line segments intersect. (line AB collides with line CD)
/// Returns a tuple containing information about the hit detection, or nil, if the lines don't intersect

public func lineIntersect(_ ptA: Vector2, ptB: Vector2, ptC: Vector2, ptD: Vector2) ->  (hitPt: Vector2, Ua: CGFloat, Ub: CGFloat)?
{
    let denom = ((ptD.Y - ptC.Y) * (ptB.X - ptA.X)) - ((ptD.X - ptC.X) * (ptB.Y - ptA.Y))
    
    // if denom == 0, lines are parallel - being a bit generous on this one..
    if (abs(denom) < 0.000000001)
    {
        return nil
    }
    
    let UaTop = ((ptD.X - ptC.X) * (ptA.Y - ptC.Y)) - ((ptD.Y - ptC.Y) * (ptA.X - ptC.X))
    let UbTop = ((ptB.X - ptA.X) * (ptA.Y - ptC.Y)) - ((ptB.Y - ptA.Y) * (ptA.X - ptC.X))
    
    let Ua = UaTop / denom
    let Ub = UbTop / denom
    
    if ((Ua >= 0) && (Ua <= 1) && (Ub >= 0) && (Ub <= 1))
    {
        // these lines intersect!
        let hitPt = ptA + ((ptB - ptA) * Ua)
        
        return (hitPt, Ua, Ub)
    }
    
    return nil
}

// Calculates a spring force, given position, velocity, spring constant, and damping factor

public func calculateSpringForce(_ posA: Vector2, velA: Vector2, posB: Vector2, velB: Vector2, distance: CGFloat, springK: CGFloat, springD:CGFloat) -> Vector2
{
    var dist = posA.distanceTo(posB)
    
    if (dist <= 0.0000005)
    {
        return Vector2.Zero
    }
    
    let BtoA = (posA - posB) / dist
    
    dist = distance - dist
    
    let relVel = velA - velB
    let totalRelVel = relVel =* BtoA
    
    return BtoA * ((dist * springK) - (totalRelVel * springD))
}

/// Returns a Vector2 that represents a point between vec1 and vec2, with a given ratio specified

public func calculateVectorRatio(_ vec1: Vector2, vec2: Vector2, ratio: CGFloat) -> Vector2
{
    return vec1 + (vec2 - vec1) * ratio
}
