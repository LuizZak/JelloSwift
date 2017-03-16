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

class Triangulate
{
    /// Triangulates a contour/polygon, returning the resulting triangulated
    /// triplet of points into a flat vector array.
    ///
    /// Also returns an array of indices that map each entry from the result
    /// vertices array back to the original provided polygon array indices.
    ///
    /// Returns nil, if the operation failed.
    public static func process(polygon: [Vector2]) -> (vertices: [Vector2], indices: [Int])? {
        
        if let indices = processIndices(polygon: polygon) {
            var points: [Vector2] = []
            for ind in indices {
                points.append(polygon[ind])
            }
            return (points, indices)
        }
        
        return nil
    }
    
    /// Triangulates a contour/polygon, returning the resulting index triplets
    /// that to the points on the polygon array to form the triangles.
    ///
    /// Returns nil, if the operation failed.
    public static func processIndices(polygon: [Vector2]) -> [Int]? {
        
        let pointCount = polygon.count
        if (pointCount < 3) {
            return nil
        }
        
        var vertexIndices: [Int]
        
        /* we want a counter-clockwise polygon in V */
        
        if (0 < Area(polygon)) {
            vertexIndices = Array(0..<pointCount)
        } else {
            vertexIndices = Array(0..<pointCount).reversed()
        }
        
        var nv = pointCount
        
        /*  remove nv-2 Vertices, creating 1 triangle every time */
        var count = 2 * nv   /* error detection */
        
        var v = nv-1
        
        var indices: [Int] = []
        
        while nv > 2 {
            /* if we loop, it is probably a non-simple polygon */
            if (0 >= count) {
                //** Triangulate: ERROR - probable bad polygon!
                return nil
            }
            
            count -= 1
            
            /* three consecutive vertices in current polygon, <u,v,w> */
            var u = v
            if (nv <= u) { /* previous */
                u = 0
            }
            
            v = u + 1
            if (nv <= v) { /* new v    */
                v = 0
            }
            
            var w = v + 1
            if (nv <= w) { /* next     */
                w = 0
            }
            
            if (Snip(contour: polygon, u: u, v: v, w: w, n: nv, V: vertexIndices)) {
                /* true names of the vertices */
                let a = vertexIndices[u]
                let b = vertexIndices[v]
                let c = vertexIndices[w]
                
                indices.append(a)
                indices.append(b)
                indices.append(c)
                
                /* remove v from remaining polygon */
                //var s = v
                for t in v+1..<nv {
                    vertexIndices[t-1] = vertexIndices[t]
                    //s += 1
                }
                
                nv -= 1
                
                /* resest error detection counter */
                count = 2*nv
            }
        }
        
        return indices
    }

    // compute area of a contour/polygon
    public static func Area(_ contour: [Vector2]) -> JFloat {
        var area: JFloat = 0.0
        var prev = contour.count - 1
        
        for cur in 0..<contour.count
        {
            area += contour[prev].x * contour[cur].y - contour[cur].x * contour[prev].y
            prev = cur
        }
        
        return area * 0.5
    }

    // decide if point Px/Py is inside triangle defined by
    // (Ax,Ay) (Bx,By) (Cx,Cy)
    public static func InsideTriangle(Ax: JFloat, Ay: JFloat,
                                      Bx: JFloat, By: JFloat,
                                      Cx: JFloat, Cy: JFloat,
                                      Px: JFloat, Py: JFloat) -> Bool {
        
        
        var ax: JFloat, ay: JFloat, bx: JFloat, by: JFloat, cx: JFloat,
            cy: JFloat, apx: JFloat, apy: JFloat, bpx: JFloat,
            bpy: JFloat, cpx: JFloat, cpy: JFloat
        
        var cCROSSap: JFloat, bCROSScp: JFloat, aCROSSbp: JFloat
        
        ax = Cx - Bx
        ay = Cy - By
        
        bx = Ax - Cx
        by = Ay - Cy
        
        cx = Bx - Ax
        cy = By - Ay
        
        apx = Px - Ax
        apy = Py - Ay
        
        bpx = Px - Bx
        bpy = Py - By
        
        cpx = Px - Cx
        cpy = Py - Cy
        
        aCROSSbp = ax*bpy - ay*bpx
        cCROSSap = cx*apy - cy*apx
        bCROSScp = bx*cpy - by*cpx
        
        return ((aCROSSbp >= 0.0) && (bCROSScp >= 0.0) && (cCROSSap >= 0.0))
    }
    
    // decide if point Px/Py is inside triangle defined by
    // (Ax,Ay) (Bx,By) (Cx,Cy)
    public static func InsideTriangle(A: Vector2, B: Vector2, C: Vector2, P: Vector2) -> Bool {
        
        var cCROSSap: JFloat, bCROSScp: JFloat, aCROSSbp: JFloat
        
        let a = C - B
        let b = A - C
        let c = B - A
        let ap = P - A
        let bp = P - B
        let cp = P - C
        
        aCROSSbp = a.x * bp.y - a.y * bp.x
        cCROSSap = c.x * ap.y - c.y * ap.x
        bCROSScp = b.x * cp.y - b.y * cp.x
        
        return ((aCROSSbp >= 0.0) && (bCROSScp >= 0.0) && (cCROSSap >= 0.0))
    }
    
    public static func Snip(contour: [Vector2], u: Int, v: Int, w: Int, n: Int, V: [Int]) -> Bool {
        
        let A = contour[V[u]]
        let B = contour[V[v]]
        let C = contour[V[w]]
        
        if (((B.x - A.x) * (C.y - A.y)) - ((B.y - A.y) * (C.x - A.x)) < JFloat.leastNonzeroMagnitude) {
            return false
        }
        
        for p in 0..<n {
            if((p == u) || (p == v) || (p == w)) {
                continue
            }
            
            let P = contour[V[p]]
            if (InsideTriangle(A: A, B: B, C: C, P: P)) {
                return false
            }
        }
        
        return true
    }
}
