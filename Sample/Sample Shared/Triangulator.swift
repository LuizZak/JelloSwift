//
//  Triangulator.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 26/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//
//  Implementation based on code found on
//  http://flipcode.net/archives/Efficient_Polygon_Triangulation.shtml
//

import JelloSwift

class Triangulate {
    /// Triangulates a contour/polygon, returning the resulting triangulated
    /// triplet of points into a flat vector array.
    ///
    /// Also returns an array of indices that map each entry from the result
    /// vertices array back to the original provided polygon array indices.
    ///
    /// Returns nil, if the operation failed.
    public static func process(polygon: [Vector2]) -> (vertices: [Vector2], indices: [Int])? {
        guard let indices = processIndices(polygon: polygon) else {
            return nil
        }
        
        var points: [Vector2] = []
        points.reserveCapacity(indices.count)
        for ind in indices {
            points.append(polygon[ind])
        }
        
        return (points, indices)
    }
    
    /// Triangulates a contour/polygon, returning the resulting index triplets
    /// that to the points on the polygon array to form the triangles.
    ///
    /// Returns nil, if the operation failed.
    public static func processIndices(polygon: [Vector2]) -> [Int]? {
        
        let pointCount = polygon.count
        if pointCount < 3 {
            return nil
        }
        
        var vertexIndices: [Int]
        
        /* we want a counter-clockwise polygon in V */
        
        if 0 < area(polygon) {
            vertexIndices = Array(0..<pointCount)
        } else {
            vertexIndices = Array(0..<pointCount).reversed()
        }
        
        var nv = pointCount
        
        /*  remove nv-2 Vertices, creating 1 triangle every time */
        var count = 2 * nv   /* error detection */
        
        var v = nv-1
        
        var indices: [Int] = []
        indices.reserveCapacity(polygon.count * 3) // Reserve some capacity to stop high reallocation
        
        while nv > 2 {
            /* if we loop, it is probably a non-simple polygon */
            if count <= 0 {
                //** Triangulate: ERROR - probable bad polygon!
                return nil
            }
            
            count -= 1
            
            /* three consecutive vertices in current polygon, <u,v,w> */
            var u = v
            if nv <= u { /* previous */
                u = 0
            }
            
            v = u + 1
            if nv <= v { /* new v    */
                v = 0
            }
            
            var w = v + 1
            if nv <= w { /* next     */
                w = 0
            }
            
            if snip(contour: polygon, u: u, v: v, w: w, n: nv, V: vertexIndices) {
                /* true names of the vertices */
                let a = vertexIndices[u]
                let b = vertexIndices[v]
                let c = vertexIndices[w]
                
                indices.append(a)
                indices.append(b)
                indices.append(c)
                
                /* remove v from remaining polygon */
                for t in v+1..<nv {
                    vertexIndices[t - 1] = vertexIndices[t]
                }
                
                nv -= 1
                
                /* resest error detection counter */
                count = 2 * nv
            }
        }
        
        return indices
    }

    // compute area of a contour/polygon
    public static func area(_ contour: [Vector2]) -> JFloat {
        var area: JFloat = 0.0
        var prev = contour.count - 1
        
        for cur in 0..<contour.count {
            area += contour[prev].x * contour[cur].y - contour[cur].x * contour[prev].y
            prev = cur
        }
        
        return area * 0.5
    }
    
    // decide if point Px/Py is inside triangle defined by
    // (Ax,Ay) (Bx,By) (Cx,Cy)
    private static func insideTriangle(A: Vector2, B: Vector2, C: Vector2, P: Vector2) -> Bool {
        let a = C - B
        let b = A - C
        let c = B - A
        let ap = P - A
        let bp = P - B
        let cp = P - C
        
        let aCROSSbp = a.cross(bp)
        let cCROSSap = c.cross(ap)
        let bCROSScp = b.cross(cp)
        
        return ((aCROSSbp >= 0.0) && (bCROSScp >= 0.0) && (cCROSSap >= 0.0))
    }
    
    private static func snip(contour: [Vector2], u: Int, v: Int, w: Int, n: Int, V: [Int]) -> Bool {
        let A = contour[V[u]]
        let B = contour[V[v]]
        let C = contour[V[w]]
        
        if ((B.x - A.x) * (C.y - A.y)) - ((B.y - A.y) * (C.x - A.x)) < .leastNonzeroMagnitude {
            return false
        }
        
        for p in 0..<n {
            if p == u || p == v || p == w {
                continue
            }
            
            let P = contour[V[p]]
            if insideTriangle(A: A, B: B, C: C, P: P) {
                return false
            }
        }
        
        return true
    }
}
