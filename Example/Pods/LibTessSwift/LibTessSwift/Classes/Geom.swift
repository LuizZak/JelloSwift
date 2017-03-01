//
//  Geom.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 27/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

internal class Geom {
    public static func IsWindingInside(_ rule: WindingRule, _ n: Int) -> Bool {
        switch (rule) {
            case WindingRule.evenOdd:
                return (n & 1) == 1
            case WindingRule.nonZero:
                return n != 0
            case WindingRule.positive:
                return n > 0
            case WindingRule.negative:
                return n < 0
            case WindingRule.absGeqTwo:
                return n >= 2 || n <= -2
        }
    }

    public static func VertCCW(_ u: MeshUtils.Vertex, _ v: MeshUtils.Vertex, _ w: MeshUtils.Vertex) -> Bool {
        return (u._s * (v._t - w._t) + v._s * (w._t - u._t) + w._s * (u._t - v._t)) >= 0.0
    }
    public static func VertEq(_ lhs: MeshUtils.Vertex, _ rhs: MeshUtils.Vertex) -> Bool {
        return lhs._s == rhs._s && lhs._t == rhs._t
    }
    public static func VertLeq(_ lhs: MeshUtils.Vertex, _ rhs: MeshUtils.Vertex) -> Bool {
        return (lhs._s < rhs._s) || (lhs._s == rhs._s && lhs._t <= rhs._t)
    }

    /// <summary>
    /// Given three vertices u,v,w such that VertLeq(u,v) && VertLeq(v,w),
    /// evaluates the t-coord of the edge uw at the s-coord of the vertex v.
    /// Returns v->t - (uw)(v->s), ie. the signed distance from uw to v.
    /// If uw is vertical (and thus passes thru v), the result is zero.
    /// 
    /// The calculation is extremely accurate and stable, even when v
    /// is very close to u or w.  In particular if we set v->t = 0 and
    /// let r be the negated result (this evaluates (uw)(v->s)), then
    /// r is guaranteed to satisfy MIN(u->t,w->t) <= r <= MAX(u->t,w->t).
    /// </summary>
    public static func EdgeEval(_ u: MeshUtils.Vertex, _ v: MeshUtils.Vertex, _ w: MeshUtils.Vertex) -> CGFloat {
        assert(VertLeq(u, v) && VertLeq(v, w))
        
        let gapL: CGFloat = v._s - u._s as CGFloat
        let gapR: CGFloat = w._s - v._s as CGFloat
        
        /* vertical line */
        if (gapL + gapR <= 0.0) {
            return 0
        }
        
        if (gapL < gapR) {
            let k = gapL / (gapL + gapR) as CGFloat
            let t1 = v._t - u._t as CGFloat
            let t2 = u._t - w._t as CGFloat
            
            return t1 + t2 * k
        } else {
            let k = gapR / (gapL + gapR) as CGFloat
            let t1 = v._t - w._t as CGFloat
            let t2 = w._t - u._t as CGFloat
            
            return t1 + t2 * k
        }
    }

    /// <summary>
    /// Returns a number whose sign matches EdgeEval(u,v,w) but which
    /// is cheaper to evaluate. Returns > 0, == 0 , or < 0
    /// as v is above, on, or below the edge uw.
    /// </summary>
    public static func EdgeSign(_ u: MeshUtils.Vertex, _ v: MeshUtils.Vertex, _ w: MeshUtils.Vertex) -> CGFloat {
        assert(VertLeq(u, v) && VertLeq(v, w))

        let gapL = v._s - u._s as CGFloat
        let gapR = w._s - v._s as CGFloat
        
        if (gapL + gapR > 0.0) {
            let t1 = (v._t - w._t) * gapL as CGFloat
            let t2 = (v._t - u._t) * gapR as CGFloat
            return t1 + t2
        }
        /* vertical line */
        return 0
    }

    public static func TransLeq(_ lhs: MeshUtils.Vertex, _ rhs: MeshUtils.Vertex) -> Bool {
        return (lhs._t < rhs._t) || (lhs._t == rhs._t && lhs._s <= rhs._s)
    }

    public static func TransEval(_ u: MeshUtils.Vertex, _ v: MeshUtils.Vertex, _ w: MeshUtils.Vertex) -> CGFloat {
        assert(TransLeq(u, v) && TransLeq(v, w))
        
        let gapL = (v._t - u._t) as CGFloat
        let gapR = (w._t - v._t) as CGFloat

        if (gapL + gapR > 0.0) {
            if (gapL < gapR) {
                let k = (gapL / (gapL + gapR)) as CGFloat
                let s1 = (v._s - u._s) as CGFloat
                let s2 = (u._s - w._s) as CGFloat
                return s1 + s2 * k
            } else {
                let k = (gapR / (gapL + gapR)) as CGFloat
                let s1 = (v._s - w._s) as CGFloat
                let s2 = (w._s - u._s) as CGFloat
                return s1 + s2 * k
            }
        }
        /* vertical line */
        return 0
    }

    public static func TransSign(_ u: MeshUtils.Vertex, _ v: MeshUtils.Vertex, _ w: MeshUtils.Vertex) -> CGFloat {
        assert(TransLeq(u, v) && TransLeq(v, w))
        
        let gapL = v._t - u._t
        let gapR = w._t - v._t
        
        if (gapL + gapR > 0.0) {
            let s1 = ((v._s - w._s) * gapL) as CGFloat
            let s2 = ((v._s - u._s) * gapR) as CGFloat
            return s1 + s2
        }
        /* vertical line */
        return 0
    }

    public static func EdgeGoesLeft(_ e: MeshUtils.Edge) -> Bool {
        return VertLeq(e._Dst!, e._Org!)
    }

    public static func EdgeGoesRight(_ e: MeshUtils.Edge) -> Bool {
        return VertLeq(e._Org!, e._Dst!)
    }

    public static func VertL1dist(u: MeshUtils.Vertex, v: MeshUtils.Vertex) -> CGFloat {
        let s = abs(u._s - v._s) as CGFloat
        let t = abs(u._t - v._t) as CGFloat
        return s + t
    }

    public static func AddWinding(_ eDst: MeshUtils.Edge, _ eSrc: MeshUtils.Edge) {
        eDst._winding += eSrc._winding
        eDst._Sym!._winding += eSrc._Sym!._winding
    }

    public static func Interpolate(_ a: CGFloat, _ x: CGFloat, _ b: CGFloat, _ y: CGFloat) -> CGFloat {
        var a = a
        var b = b
        if (a < 0.0) {
            a = 0.0
        }
        if (b < 0.0) {
            b = 0.0
        }
        
        return ((a <= b) ? ((b == 0.0) ? ((x+y) / 2.0)
                : (x + (y-x) * (a/(a+b))))
                : (y + (x-y) * (b/(a+b))))
    }
    
    /// <summary>
    /// Given edges (o1,d1) and (o2,d2), compute their point of intersection.
    /// The computed point is guaranteed to lie in the intersection of the
    /// bounding rectangles defined by each edge.
    /// </summary>
    public static func EdgeIntersect(o1: MeshUtils.Vertex, d1: MeshUtils.Vertex, o2: MeshUtils.Vertex, d2: MeshUtils.Vertex, v: MeshUtils.Vertex) {
        var o1 = o1
        var d1 = d1
        var o2 = o2
        var d2 = d2
        // This is certainly not the most efficient way to find the intersection
        // of two line segments, but it is very numerically stable.
        // 
        // Strategy: find the two middle vertices in the VertLeq ordering,
        // and interpolate the intersection s-value from these.  Then repeat
        // using the TransLeq ordering to find the intersection t-value.
        
        if (!VertLeq(o1, d1)) { swap(&o1, &d1) }
        if (!VertLeq(o2, d2)) { swap(&o2, &d2) }
        if (!VertLeq(o1, o2)) { swap(&o1, &o2); swap(&d1, &d2) }

        if (!VertLeq(o2, d1)) {
            // Technically, no intersection -- do our best
            v._s = (o2._s + d1._s) / 2.0
        } else if (VertLeq(d1, d2)) {
            // Interpolate between o2 and d1
            var z1 = EdgeEval(o1, o2, d1)
            var z2 = EdgeEval(o2, d1, d2)
            if (z1 + z2 < 0.0) {
                z1 = -z1
                z2 = -z2
            }
            v._s = Interpolate(z1, o2._s, z2, d1._s)
        } else {
            // Interpolate between o2 and d2
            var z1 = EdgeSign(o1, o2, d1)
            var z2 = -EdgeSign(o1, d2, d1)
            if (z1 + z2 < 0.0) {
                z1 = -z1
                z2 = -z2
            }
            v._s = Interpolate(z1, o2._s, z2, d2._s)
        }

        // Now repeat the process for t

        if (!TransLeq(o1, d1)) { swap(&o1, &d1) }
        if (!TransLeq(o2, d2)) { swap(&o2, &d2) }
        if (!TransLeq(o1, o2)) { swap(&o1, &o2); swap(&d1, &d2) }
        
        if (!TransLeq(o2, d1)) {
            // Technically, no intersection -- do our best
            v._t = (o2._t + d1._t) / 2.0
        } else if (TransLeq(d1, d2)) {
            // Interpolate between o2 and d1
            var z1 = TransEval(o1, o2, d1)
            var z2 = TransEval(o2, d1, d2)
            if (z1 + z2 < 0.0) {
                z1 = -z1
                z2 = -z2
            }
            v._t = Interpolate(z1, o2._t, z2, d1._t)
        } else {
            // Interpolate between o2 and d2
            var z1 = TransSign(o1, o2, d1)
            var z2 = -TransSign(o1, d2, d1)
            if (z1 + z2 < 0.0) {
                z1 = -z1
                z2 = -z2
            }
            v._t = Interpolate(z1, o2._t, z2, d2._t)
        }
    }
}
