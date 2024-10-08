//
//  GeomUtils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Returns an approximation of the area of the polygon defined by a given set
/// of vertices
@_specialize(where T == Array<Vector2>)
@_specialize(where T == ContiguousArray<PointMass>)
public func polygonArea<T: BidirectionalCollection>(of points: T) -> JFloat where T.Iterator.Element: VectorRepresentable {
    guard var v2 = points.last else {
        return 0
    }

    var area: JFloat = 0

    for p in points {
        area -= v2.vector.cross(p.vector)
        v2 = p
    }

    return area / 2
}

/// Checks if 2 line segments intersect. (line A collides with line B)
/// Returns a tuple containing information about the hit detection, or nil, if
/// the lines don't intersect
@inlinable
public func lineIntersect(
    lineA: (start: Vector2, end: Vector2),
    lineB: (start: Vector2, end: Vector2)
) -> (hitPt: Vector2, Ua: JFloat, Ub: JFloat)? {
    let denom = ((lineB.end.y - lineB.start.y) * (lineA.end.x - lineA.start.x)) - ((lineB.end.x - lineB.start.x) * (lineA.end.y - lineA.start.y))

    // if denom == 0, lines are parallel - being a bit generous on this one..
    if abs(denom) < .leastNonzeroMagnitude {
        return nil
    }

    let UaTop = ((lineB.end.x - lineB.start.x) * (lineA.start.y - lineB.start.y)) - ((lineB.end.y - lineB.start.y) * (lineA.start.x - lineB.start.x))
    let UbTop = ((lineA.end.x - lineA.start.x) * (lineA.start.y - lineB.start.y)) - ((lineA.end.y - lineA.start.y) * (lineA.start.x - lineB.start.x))

    let Ua = UaTop / denom
    let Ub = UbTop / denom

    if Ua >= 0 && Ua <= 1 && Ub >= 0 && Ub <= 1 {
        // these lines intersect!
        let hitPt = lineA.start + ((lineA.end - lineA.start) * Ua)

        return (hitPt, Ua, Ub)
    }

    return nil
}

/// Returns a Vector2 that represents a point between vec1 and vec2, with a
/// given ratio specified
@inlinable
public func calculateVectorRatio(_ vec1: Vector2, vec2: Vector2, ratio: JFloat) -> Vector2 {
    return vec1 + (vec2 - vec1) * ratio
}
