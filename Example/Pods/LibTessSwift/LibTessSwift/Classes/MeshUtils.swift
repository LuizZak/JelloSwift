//
//  MeshUtils.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 26/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

/// Objects that can be initialized using a parameterless init
public protocol EmptyInitializable {
    init()
}

public struct Vec3: CustomStringConvertible, EmptyInitializable {
    public static var Zero = Vec3()

    public var X: CGFloat, Y: CGFloat, Z: CGFloat

    public subscript(index: Int) -> CGFloat {
        get {
            if (index == 0) { return X }
            if (index == 1) { return Y }
            if (index == 2) { return Z }
            fatalError("out of bounds")
        }
        set {
            if (index == 0) { X = newValue } else if (index == 1) { Y = newValue } else if (index == 2) { Z = newValue }
        }
    }
    
    public init(X: CGFloat, Y: CGFloat, Z: CGFloat) {
        self.X = X
        self.Y = Y
        self.Z = Z
    }
    
    public init() {
        self.X = 0
        self.Y = 0
        self.Z = 0
    }

    public static func Sub(lhs: inout Vec3, rhs: inout Vec3, result: inout Vec3)  {
        result.X = lhs.X - rhs.X
        result.Y = lhs.Y - rhs.Y
        result.Z = lhs.Z - rhs.Z
    }

    public static func Neg(v: inout Vec3) {
        v.X = -v.X
        v.Y = -v.Y
        v.Z = -v.Z
    }

    public static func Dot(u: inout Vec3, v: inout Vec3, dot: inout CGFloat) {
        dot = u.X * v.X + u.Y * v.Y + u.Z * v.Z
    }

    public static func Normalize(v: inout Vec3) {
        
        var len: CGFloat = v.X * v.X + v.Y * v.Y + v.Z * v.Z
        
        assert(len >= 0.0)
        
        len = 1.0 / sqrt(len)
        v.X *= len
        v.Y *= len
        v.Z *= len
    }

    public static func LongAxis(v: inout Vec3) -> Int {
        var i = 0
        if (abs(v.Y) > abs(v.X)) { i = 1 }
        if (abs(v.Z) > abs(i == 0 ? v.X : v.Y)) { i = 2 }
        
        return i
    }

    public var description: String {
        return "\(X), \(Y), \(Z)"
    }
}

/// Describes an object that can be chained with other instances of itself
/// indefinitely. This also supports looped links that point circularly.
internal protocol Linked: class {
    var _next: Self! { get }
    
    /// Loops over each element, starting from this instance, until
    /// either _next is nil, or the check closure returns false.
    ///
    /// This method captures the next element before calling the closure,
    /// so it's safe to change the element's _next pointer within it.
    func loop(while check: (_ element: Self) throws -> Bool, with closure: (_ element: Self) throws -> (Void)) rethrows
    
    /// Iterates over each element, starting from this instance, until
    /// either _next is nil, or _next points to this element.
    ///
    /// The closure returns a value specifying whether the loop should
    /// be stopped.
    ///
    /// This method captures the next element before calling the closure,
    /// so it's safe to change the element's _next pointer within it.
    func loop(with closure: (_ element: Self) throws -> (Void)) rethrows
}

extension Linked {
    
    func loop(while check: (_ element: Self) throws -> Bool, with closure: (_ element: Self) throws -> (Void)) rethrows {
        var f: Self! = self
        var next: Self?
        repeat {
            guard let n = f else {
                break
            }
            
            defer {
                f = next
            }
            
            next = n._next
            try closure(n)
        } while try f != nil && check(f)
    }
    
    func loop(with closure: (_ element: Self) throws -> (Void)) rethrows {
        let start = self
        try loop(while: { $0 !== start }, with: closure)
    }
}

internal class MeshUtils {
    
    public static let Undef: Int = ~0
    
    public final class Vertex: Linked, EmptyInitializable {
        internal weak var _prev: Vertex!
        internal weak var _next: Vertex!
        internal weak var _anEdge: Edge!

        internal var _coords: Vec3 = .Zero
        internal var _s: CGFloat = 0, _t: CGFloat = 0
        internal var _pqHandle: PQHandle = PQHandle()
        internal var _n: Int = 0
        internal var _data: Any?
        
        init() {
            
        }

        public func Reset() {
            _prev = nil
            _next = nil
            _anEdge = nil
            _coords = Vec3.Zero
            _s = 0
            _t = 0
            _pqHandle = PQHandle()
            _n = 0
            _data = nil
        }
    }

    public final class Face: Linked, EmptyInitializable {
        internal weak var _prev: Face!
        internal var _next: Face!
        internal var _anEdge: Edge!
        
        internal var _n: Int = 0
        internal var _marked = false, _inside = false

        internal var VertsCount: Int {
            var n = 0
            var eCur = _anEdge
            repeat {
                n += 1
                eCur = eCur?._Lnext
            } while (eCur !== _anEdge)
            return n
        }
        
        init() {
            
        }
        
        public func Reset() {
            _prev = nil
            _next = nil
            _anEdge = nil
            _n = 0
            _marked = false
            _inside = false
        }
    }

    public struct EdgePair {
        internal weak var _e: Edge?
        internal weak var _eSym: Edge?
        
        public mutating func Reset() {
            _e = nil
            _eSym = nil
        }
    }

    public final class Edge: Linked, EmptyInitializable {
        public static var pool: ContiguousArray<MeshUtils.Edge> = []
        
        internal var _pair: EdgePair?
        internal weak var _next: Edge!
        internal weak var _Sym: Edge!
        internal weak var _Onext: Edge!
        internal var _Lnext: Edge!
        internal var _Org: Vertex!
        internal weak var _Lface: Face!
        internal weak var _activeRegion: Tess.ActiveRegion!
        internal var _winding: Int = 0

        internal var _Rface: Face! { get { return _Sym?._Lface } set { _Sym?._Lface = newValue } }
        internal var _Dst: Vertex! { get { return _Sym?._Org }  set { _Sym?._Org = newValue } }

        internal var _Oprev: Edge! { get { return _Sym?._Lnext } set { _Sym?._Lnext = newValue } }
        internal var _Lprev: Edge! { get { return _Onext?._Sym } set { _Onext?._Sym = newValue } }
        internal var _Dprev: Edge! { get { return _Lnext._Sym } set { _Lnext._Sym = newValue } }
        internal var _Rprev: Edge! { get { return _Sym?._Onext } set { _Sym?._Onext = newValue } }
        internal var _Dnext: Edge! { get { return _Rprev?._Sym } set { _Rprev?._Sym = newValue } }
        internal var _Rnext: Edge! { get { return _Oprev?._Sym } set { _Oprev?._Sym = newValue } }
        
        internal static func EnsureFirst(e: inout Edge) {
            if (e === e._pair?._eSym) {
                e = e._Sym
            }
        }
        
        public init() {
            
        }

        public func Reset() {
            _pair?.Reset()
            _next = nil
            _Sym = nil
            _Onext = nil
            _Lnext = nil
            _Org = nil
            _Lface = nil
            _activeRegion = nil
            _winding = 0
        }
    }
    
    /// <summary>
    /// Splice( a, b ) is best described by the Guibas/Stolfi paper or the
    /// CS348a notes (see Mesh.cs). Basically it modifies the mesh so that
    /// a->Onext and b->Onext are exchanged. This can have various effects
    /// depending on whether a and b belong to different face or vertex rings.
    /// For more explanation see Mesh.Splice().
    /// </summary>
    public static func Splice(_ a: Edge, _ b: Edge) {
        let aOnext = a._Onext
        let bOnext = b._Onext
        
        aOnext?._Sym?._Lnext = b
        bOnext?._Sym?._Lnext = a
        a._Onext = bOnext
        b._Onext = aOnext
    }
    
    /// <summary>
    /// Return signed area of face.
    /// </summary>
    public static func FaceArea(_ f: Face) -> CGFloat {
        var area: CGFloat = 0
        var e = f._anEdge!
        repeat {
            area += (e._Org._s - e._Dst._s) * (e._Org._t + e._Dst._t)
            e = e._Lnext
        } while (e !== f._anEdge)
        return area
    }
}
