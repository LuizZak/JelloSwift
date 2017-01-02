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
public func polygonArea<T: BidirectionalCollection>(_ points: T) -> CGFloat where T.Iterator.Element: VectorExpressible
{
    var area: CGFloat = 0
    
    if var v2 = points.last
    {
        for p in points
        {
            area += (v2.vector.x + p.vector.x) * (v2.vector.y - p.vector.y)
            v2 = p
        }
    }
    
    return area / 2
}

/// Checks if 2 line segments intersect. (line AB collides with line CD)
/// Returns a tuple containing information about the hit detection, or nil, if the lines don't intersect
public func lineIntersect(_ ptA: Vector2, ptB: Vector2, ptC: Vector2, ptD: Vector2) ->  (hitPt: Vector2, Ua: CGFloat, Ub: CGFloat)?
{
    let denom = ((ptD.y - ptC.y) * (ptB.x - ptA.x)) - ((ptD.x - ptC.x) * (ptB.y - ptA.y))
    
    // if denom == 0, lines are parallel - being a bit generous on this one..
    if (abs(denom) < 0.000000001)
    {
        return nil
    }
    
    let UaTop = ((ptD.x - ptC.x) * (ptA.y - ptC.y)) - ((ptD.y - ptC.y) * (ptA.x - ptC.x))
    let UbTop = ((ptB.x - ptA.x) * (ptA.y - ptC.y)) - ((ptB.y - ptA.y) * (ptA.x - ptC.x))
    
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
public func calculateSpringForce(posA: Vector2, velA: Vector2, posB: Vector2, velB: Vector2, distance: CGFloat, springK: CGFloat, springD: CGFloat) -> Vector2
{
    var dist = posA.distanceTo(posB)
    
    if (dist <= 0.0000005)
    {
        return Vector2.zero
    }
    
    let BtoA = (posA - posB) / dist
    
    dist = distance - dist
    
    let relVel = velA - velB
    let totalRelVel = relVel • BtoA
    
    return BtoA * ((dist * springK) - (totalRelVel * springD))
}

/// Returns a Vector2 that represents a point between vec1 and vec2, with a given ratio specified
public func calculateVectorRatio(_ vec1: Vector2, vec2: Vector2, ratio: CGFloat) -> Vector2
{
    return vec1 + (vec2 - vec1) * ratio
}
