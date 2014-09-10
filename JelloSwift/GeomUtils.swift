//
//  GeomUtils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

func polygonArea(points: [Vector2]) -> CGFloat
{
    var area: CGFloat = 0;
    var j:Int = points.count - 1;
    
    for i in 0..<points.count
    {
        area += (points[j].X + points[i].X) * (points[j].Y - points[i].Y);
        j = i;
    }
    
    return area / 2;
}

func polygonArea(points: [PointMass]) -> CGFloat
{
    var area: CGFloat = 0;
    var j:Int = points.count - 1;
    let c:Int = points.count;
    
    for i in 0..<c
    {
        area += (points[j].position.X + points[i].position.X) * (points[j].position.Y - points[i].position.Y);
        j = i;
    }
    
    return area / 2;
}

/// Checks if 2 line segments intersect. (line AB collides with line CD) (reference type version)
func lineIntersect(ptA: Vector2, ptB: Vector2, ptC: Vector2, ptD: Vector2, inout hitPt: Vector2, inout Ua: CGFloat, inout Ub: CGFloat) -> Bool
{
    var denom = ((ptD.Y - ptC.Y) * (ptB.X - ptA.X)) - ((ptD.X - ptC.X) * (ptB.Y - ptA.Y));
    
    // if denom == 0, lines are parallel - being a bit generous on this one..
    if (abs(denom) < 0.000000001)
    {
        return false;
    }
    
    var UaTop = ((ptD.X - ptC.X) * (ptA.Y - ptC.Y)) - ((ptD.Y - ptC.Y) * (ptA.X - ptC.X));
    var UbTop = ((ptB.X - ptA.X) * (ptA.Y - ptC.Y)) - ((ptB.Y - ptA.Y) * (ptA.X - ptC.X));
    
    var revDenom = 1 / denom;
    
    Ua = UaTop * revDenom;
    Ub = UbTop * revDenom;
    
    if ((Ua >= 0) && (Ua <= 1) && (Ub >= 0) && (Ub <= 1))
    {
        // these lines intersect!
        hitPt = ptA + ((ptB - ptA) * Ua);
        
        return true;
    }
    
    return false;
}

// Calculates a spring force, given position, velocity, spring constant, and damping factor
func calculateSpringForce(posA: Vector2, velA: Vector2, posB: Vector2, velB: Vector2, springD: CGFloat, springK: CGFloat, damping:CGFloat) -> Vector2
{
    var BtoA = posA - posB;
    
    var dist = posA.distance(posB);
    
    if (dist > 0.005)
    {
        BtoA *= 1.0 / dist;
    }
    else
    {
        return Vector2(0, 0);
    }
    
    dist = springD - dist;
    
    var relVel = velA - velB;
    var totalRelVel = relVel =* BtoA;
    
    return BtoA * ((dist * springK) - (totalRelVel * damping));
}