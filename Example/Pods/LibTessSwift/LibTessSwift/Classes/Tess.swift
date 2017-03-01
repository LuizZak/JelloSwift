//
//  Tess.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 26/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import simd

public enum WindingRule: String {
    case evenOdd
    case nonZero
    case positive
    case negative
    case absGeqTwo
}

public enum ElementType {
    case polygons
    case connectedPolygons
    case boundaryContours
}

public enum ContourOrientation {
    case original
    case clockwise
    case counterClockwise
}

public struct ContourVertex: CustomStringConvertible {
    public var position: Vector3
    public var data: Any?
    
    public init() {
        position = .zero
        data = nil
    }
    
    public init(Position: Vector3) {
        self.position = Position
        self.data = nil
    }
    
    public init(Position: Vector3, Data: Any?) {
        self.position = Position
        self.data = Data
    }
    
    public var description: String {
        return "\(position), \(data)"
    }
}

public typealias CombineCallback = (_ position: Vector3, _ data: [Any?], _ weights: [Real]) -> Any?

public class Tess {
    internal var _mesh: Mesh!
    internal var _normal: Vector3
    internal var _sUnit: Vector3 = .zero
    internal var _tUnit: Vector3 = .zero

    internal var _bminX: Real
    internal var _bminY: Real
    internal var _bmaxX: Real
    internal var _bmaxY: Real

    internal var _windingRule: WindingRule

    internal var _dict: Dict<ActiveRegion>!
    internal var _pq: PriorityQueue<MeshUtils.Vertex>!
    internal var _event: MeshUtils.Vertex!
    
    internal var _regionsPool = Pool<ActiveRegion>()

    internal var _combineCallback: CombineCallback?

    internal var _vertices: [ContourVertex]!
    internal var _vertexCount: Int
    internal var _elements: [Int]!
    internal var _elementCount: Int
    
    public var normal: Vector3 { get { return _normal } set { _normal = newValue } }
    
    public var SUnitX: Real = 1
    public var SUnitY: Real = 0
#if DOUBLE
    public var SentinelCoord: Real = 4e150
#else
    public var SentinelCoord: Real = 4e30
#endif

    /// <summary>
    /// If true, will remove empty (zero area) polygons.
    /// </summary>
    public var noEmptyPolygons = false
    
    public var vertices: [ContourVertex]! { get { return _vertices } }
    public var vertexCount: Int { get { return _vertexCount } }
    
    public var elements: [Int]! { get { return _elements } }
    public var elementCount: Int { get { return _elementCount } }
    
    public init() {
        _normal = Vector3.zero
        _bminX = 0
        _bminY = 0
        _bmaxX = 0
        _bmaxY = 0

        _windingRule = WindingRule.evenOdd
        _mesh = nil
        
        _vertices = nil
        _vertexCount = 0
        _elements = nil
        _elementCount = 0
    }
    
    deinit {
        _mesh = nil
        
        for created in _regionsPool.totalCreated {
            created._eUp = nil
            created._nodeUp?.Key = nil
            created._nodeUp = nil
        }
        
        _regionsPool.reset()
    }
    
    private func computeNormal(norm: inout Vector3) {
        var v = _mesh._vHead._next!

        var minVal: [Real] = [ v._coords.x, v._coords.y, v._coords.z ]
        var minVert: ContiguousArray<MeshUtils.Vertex> = [ v, v, v ]
        var maxVal: [Real] = [ v._coords.x, v._coords.y, v._coords.z ]
        var maxVert: ContiguousArray<MeshUtils.Vertex> = [ v, v, v ]
        
        func subMinMax(_ index: Int) -> Real {
            return maxVal[index] - minVal[index]
        }
        
        _mesh.forEachVertex { v in
            if (v._coords.x < minVal[0]) {
                minVal[0] = v._coords.x
                minVert[0] = v
            }
            if (v._coords.y < minVal[1]) {
                minVal[1] = v._coords.y
                minVert[1] = v
            }
            if (v._coords.z < minVal[2]) {
                minVal[2] = v._coords.z
                minVert[2] = v }
            
            if (v._coords.x > maxVal[0]) {
                maxVal[0] = v._coords.x
                maxVert[0] = v
            }
            if (v._coords.y > maxVal[1]) {
                maxVal[1] = v._coords.y
                maxVert[1] = v
            }
            if (v._coords.z > maxVal[2]) {
                maxVal[2] = v._coords.z
                maxVert[2] = v
            }
        }
        
        // Find two vertices separated by at least 1/sqrt(3) of the maximum
        // distance between any two vertices
        var i = 0
        
        if subMinMax(1) > subMinMax(0) {
            i = 1
        }
        
        if subMinMax(2) > subMinMax(i) {
            i = 2
        }
        
        if (minVal[i] >= maxVal[i]) {
            // All vertices are the same -- normal doesn't matter
            norm = Vector3(x: 0, y: 0, z: 1)
            return
        }
        
        // Look for a third vertex which forms the triangle with maximum area
        // (Length of normal == twice the triangle area)
        var maxLen2: Real = 0
        let v1 = minVert[i]
        let v2 = maxVert[i]
        
        var tNorm: Vector3 = .zero
        var d1 = v1._coords - v2._coords
        
        _mesh.forEachVertex { v in
            
            let d2 = v._coords - v2._coords
            
            tNorm.x = d1.y * d2.z - d1.z * d2.y
            tNorm.y = d1.z * d2.x - d1.x * d2.z
            tNorm.z = d1.x * d2.y - d1.y * d2.x
            let tLen2 = tNorm.x * tNorm.x + tNorm.y * tNorm.y + tNorm.z * tNorm.z
            
            if (tLen2 > maxLen2) {
                maxLen2 = tLen2
                norm = tNorm
            }
        }
        
        if (maxLen2 <= 0.0) {
            // All points lie on a single line -- any decent normal will do
            norm = Vector3.zero
            i = Vector3.longAxis(v: &d1)
            norm[i] = 1
        }
    }

    private func checkOrientation() {
        // When we compute the normal automatically, we choose the orientation
        // so that the the sum of the signed areas of all contours is non-negative.
        var area: Real = 0.0
        
        _mesh.forEachFace { f in
            if (f._anEdge!._winding <= 0) {
                return
            }
            area += MeshUtils.FaceArea(f)
        }
        
        if (area < 0.0) {
            // Reverse the orientation by flipping all the t-coordinates
            _mesh.forEachVertex { v in
                v._t = -v._t
            }
            
            _tUnit = -_tUnit
        }
    }

    private func projectPolygon() {
        var norm = _normal

        var computedNormal = false
        if (norm.x == 0.0 && norm.y == 0.0 && norm.z == 0.0) {
            computeNormal(norm: &norm)
            _normal = norm
            computedNormal = true
        }

        let i = Vector3.longAxis(v: &norm)
        
        _sUnit[i] = 0
        _sUnit[(i + 1) % 3] = SUnitX
        _sUnit[(i + 2) % 3] = SUnitY

        _tUnit[i] = 0
        _tUnit[(i + 1) % 3] = norm[i] > 0.0 ? -SUnitY : SUnitY
        _tUnit[(i + 2) % 3] = norm[i] > 0.0 ? SUnitX : -SUnitX

        // Project the vertices onto the sweep plane
        _mesh.forEachVertex { v in
            v._s = dot(v._coords, _sUnit)
            v._t = dot(v._coords, _tUnit)
        }
        
        if (computedNormal) {
            checkOrientation()
        }

        // Compute ST bounds.
        var first = true
        
        _mesh.forEachVertex { v in
            if (first) {
                _bmaxX = v._s
                _bminX = v._s
                
                _bmaxY = v._t
                _bminY = v._t
                first = false
            } else {
                if (v._s < _bminX) { _bminX = v._s }
                if (v._s > _bmaxX) { _bmaxX = v._s }
                if (v._t < _bminY) { _bminY = v._t }
                if (v._t > _bmaxY) { _bmaxY = v._t }
            }
        }
    }

    /// <summary>
    /// TessellateMonoRegion( face ) tessellates a monotone region
    /// (what else would it do??)  The region must consist of a single
    /// loop of half-edges (see mesh.h) oriented CCW.  "Monotone" in this
    /// case means that any vertical line intersects the interior of the
    /// region in a single interval.  
    /// 
    /// Tessellation consists of adding interior edges (actually pairs of
    /// half-edges), to split the region into non-overlapping triangles.
    /// 
    /// The basic idea is explained in Preparata and Shamos (which I don't
    /// have handy right now), although their implementation is more
    /// complicated than this one.  The are two edge chains, an upper chain
    /// and a lower chain.  We process all vertices from both chains in order,
    /// from right to left.
    /// 
    /// The algorithm ensures that the following invariant holds after each
    /// vertex is processed: the untessellated region consists of two
    /// chains, where one chain (say the upper) is a single edge, and
    /// the other chain is concave.  The left vertex of the single edge
    /// is always to the left of all vertices in the concave chain.
    /// 
    /// Each step consists of adding the rightmost unprocessed vertex to one
    /// of the two chains, and forming a fan of triangles from the rightmost
    /// of two chain endpoints.  Determining whether we can add each triangle
    /// to the fan is a simple orientation test.  By making the fan as large
    /// as possible, we restore the invariant (check it yourself).
    /// </summary>
    private func tessellateMonoRegion(_ face: MeshUtils.Face) {
        // All edges are oriented CCW around the boundary of the region.
        // First, find the half-edge whose origin vertex is rightmost.
        // Since the sweep goes from left to right, face->anEdge should
        // be close to the edge we want.
        var up = face._anEdge!
        assert(up._Lnext !== up && up._Lnext._Lnext !== up)
        
        while (Geom.VertLeq(up._Dst!, up._Org!)) { up = up._Lprev! }
        while (Geom.VertLeq(up._Org!, up._Dst!)) { up = up._Lnext }
        
        var lo = up._Lprev!
        
        while (up._Lnext !== lo) {
            if (Geom.VertLeq(up._Dst, lo._Org)) {
                // up.Dst is on the left. It is safe to form triangles from lo.Org.
                // The EdgeGoesLeft test guarantees progress even when some triangles
                // are CW, given that the upper and lower chains are truly monotone.
                while (lo._Lnext !== up && (Geom.EdgeGoesLeft(lo._Lnext)
                    || Geom.EdgeSign(lo._Org, lo._Dst, lo._Lnext._Dst) <= 0.0)) {
                    lo = _mesh.Connect(lo._Lnext, lo)._Sym
                }
                lo = lo._Lprev
            } else {
                // lo.Org is on the left.  We can make CCW triangles from up.Dst.
                while (lo._Lnext !== up && (Geom.EdgeGoesRight(up._Lprev)
                    || Geom.EdgeSign(up._Dst, up._Org, up._Lprev._Org) >= 0.0)) {
                    up = _mesh.Connect(up, up._Lprev)._Sym
                }
                up = up._Lnext
            }
        }
        
        // Now lo.Org == up.Dst == the leftmost vertex.  The remaining region
        // can be tessellated in a fan from this leftmost vertex.
        assert(lo._Lnext !== up)
        while (lo._Lnext._Lnext !== up) {
            lo = _mesh.Connect(lo._Lnext, lo)._Sym
        }
    }

    /// <summary>
    /// TessellateInterior( mesh ) tessellates each region of
    /// the mesh which is marked "inside" the polygon. Each such region
    /// must be monotone.
    /// </summary>
    private func tessellateInterior() {
        _mesh.forEachFace { f in
            if (f._inside) {
                tessellateMonoRegion(f)
            }
        }
    }

    /// <summary>
    /// DiscardExterior zaps (ie. sets to nil) all faces
    /// which are not marked "inside" the polygon.  Since further mesh operations
    /// on nil faces are not allowed, the main purpose is to clean up the
    /// mesh so that exterior loops are not represented in the data structure.
    /// </summary>
    private func discardExterior() {
        _mesh.forEachFace { f in
            if(!f._inside) {
                _mesh.ZapFace(f)
            }
        }
    }

    /// <summary>
    /// SetWindingNumber( value, keepOnlyBoundary ) resets the
    /// winding numbers on all edges so that regions marked "inside" the
    /// polygon have a winding number of "value", and regions outside
    /// have a winding number of 0.
    /// 
    /// If keepOnlyBoundary is TRUE, it also deletes all edges which do not
    /// separate an interior region from an exterior one.
    /// </summary>
    private func setWindingNumber(_ value: Int, _ keepOnlyBoundary: Bool) {
        
        _mesh.forEachEdge { e in
            if (e._Rface._inside != e._Lface._inside) {
                
                /* This is a boundary edge (one side is interior, one is exterior). */
                e._winding = (e._Lface._inside) ? value : -value
            } else {
                
                /* Both regions are interior, or both are exterior. */
                if (!keepOnlyBoundary) {
                    e._winding = 0
                } else {
                    _mesh.Delete(e)
                }
            }
        }
    }
    
    private func getNeighbourFace(_ edge: MeshUtils.Edge) -> Int {
        if (edge._Rface == nil) {
            return MeshUtils.Undef
        }
        if (!edge._Rface!._inside) {
            return MeshUtils.Undef
        }
        return edge._Rface!._n
    }
    
    private func outputPolymesh(_ elementType: ElementType, _ polySize: Int) {
        var maxFaceCount = 0
        var maxVertexCount = 0
        var faceVerts: Int = 0
        var polySize = polySize

        if (polySize < 3) {
            polySize = 3
        }
        // Assume that the input data is triangles now.
        // Try to merge as many polygons as possible
        if (polySize > 3) {
            _mesh.MergeConvexFaces(maxVertsPerFace: polySize)
        }

        // Mark unused
        _mesh.forEachVertex { v in
            v._n = MeshUtils.Undef
        }
        
        // Create unique IDs for all vertices and faces.
        _mesh.forEachFace { f in
            f._n = MeshUtils.Undef
            if (!f._inside) { return }
            
            if (noEmptyPolygons) {
                let area = MeshUtils.FaceArea(f)
                if (abs(area) < Real.leastNonzeroMagnitude) {
                    return
                }
            }
            
            var edge = f._anEdge!
            faceVerts = 0
            repeat {
                let v = edge._Org!
                if (v._n == MeshUtils.Undef) {
                    v._n = maxVertexCount
                    maxVertexCount += 1
                }
                faceVerts += 1
                edge = edge._Lnext
            } while (edge !== f._anEdge)
            
            assert(faceVerts <= polySize)
            
            f._n = maxFaceCount
            maxFaceCount += 1
        }

        _elementCount = maxFaceCount
        if (elementType == ElementType.connectedPolygons) {
            maxFaceCount *= 2
        }
        _elements = Array(repeating: 0, count: maxFaceCount * polySize)

        _vertexCount = maxVertexCount
        _vertices = Array(repeating: ContourVertex(Position: .zero, Data: nil), count: _vertexCount)

        // Output vertices.
        _mesh.forEachVertex { v in
            if (v._n != MeshUtils.Undef) {
                // Store coordinate
                _vertices[v._n].position = v._coords
                _vertices[v._n].data = v._data
            }
        }
        
        // Output indices.
        var elementIndex = 0
        
        _mesh.forEachFace { f in
            if (!f._inside) { return }
            
            if (noEmptyPolygons) {
                let area = MeshUtils.FaceArea(f)
                if (abs(area) < Real.leastNonzeroMagnitude) {
                    return
                }
            }
            
            // Store polygon
            var edge = f._anEdge!
            faceVerts = 0
            repeat {
                let v = edge._Org!
                _elements[elementIndex] = v._n
                elementIndex += 1
                faceVerts += 1
                edge = edge._Lnext
            } while (edge !== f._anEdge)
            // Fill unused.
            for _ in faceVerts..<polySize {
                _elements[elementIndex] = MeshUtils.Undef
                elementIndex += 1
            }
            
            // Store polygon connectivity
            if (elementType == ElementType.connectedPolygons) {
                edge = f._anEdge!
                repeat {
                    _elements[elementIndex] = getNeighbourFace(edge)
                    elementIndex += 1
                    edge = edge._Lnext
                } while (edge !== f._anEdge)
                
                // Fill unused.
                for _ in faceVerts..<polySize {
                    _elements[elementIndex] = MeshUtils.Undef
                    elementIndex += 1
                }
            }
        }
    }
    
    private func outputContours() {
        var startVert = 0
        var vertCount = 0
        
        _vertexCount = 0
        _elementCount = 0
        
        _mesh.forEachFace { f in
            if (!f._inside) {
                return
            }
            
            let start = f._anEdge!
            var edge = f._anEdge!
            repeat {
                _vertexCount += 1
                edge = edge._Lnext
            } while (edge !== start)
            
            _elementCount += 1
        }

        _elements = Array(repeating: 0, count: _elementCount * 2)
        _vertices = Array(repeating: ContourVertex(Position: .zero, Data: nil), count: _vertexCount)

        var vertIndex = 0
        var elementIndex = 0
        
        startVert = 0
        
        _mesh.forEachFace { f in
            if (!f._inside) {
                return
            }
            
            vertCount = 0
            let start = f._anEdge!
            var edge = f._anEdge!
            repeat {
                _vertices[vertIndex].position = edge._Org._coords
                _vertices[vertIndex].data = edge._Org._data
                vertIndex += 1
                vertCount += 1
                edge = edge._Lnext
            } while (edge !== start)
            
            _elements[elementIndex] = startVert
            elementIndex += 1
            _elements[elementIndex] = vertCount
            elementIndex += 1
            
            startVert += vertCount
        }
    }

    private func signedArea(_ vertices: [ContourVertex]) -> Real {
        var area: Real = 0.0
        
        for i in 0..<vertices.count {
            let v0 = vertices[i]
            let v1 = vertices[(i + 1) % vertices.count]

            area += v0.position.x * v1.position.y
            area -= v0.position.y * v1.position.x
        }

        return 0.5 * area
    }

    public func addContour(_ vertices: [ContourVertex]) {
        addContour(vertices, ContourOrientation.original)
    }

    public func addContour(_ vertices: [ContourVertex], _ forceOrientation: ContourOrientation) {
        if (_mesh == nil) {
            _mesh = Mesh()
        }

        var reverse = false
        if (forceOrientation != ContourOrientation.original) {
            let area = signedArea(vertices)
            reverse = (forceOrientation == ContourOrientation.clockwise && area < 0.0) || (forceOrientation == ContourOrientation.counterClockwise && area > 0.0)
        }

        var e: MeshUtils.Edge! = nil
        for i in 0..<vertices.count {
            if (e == nil) {
                e = _mesh.MakeEdge()
                _mesh.Splice(e, e._Sym)
            } else {
                // Create a new vertex and edge which immediately follow e
                // in the ordering around the left face.
                _=_mesh.SplitEdge(e)
                e = e._Lnext
            }
            
            let index = reverse ? vertices.count - 1 - i : i
            // The new vertex is now e._Org.
            e._Org._coords = vertices[index].position
            e._Org._data = vertices[index].data

            // The winding of an edge says how the winding number changes as we
            // cross from the edge's right face to its left face.  We add the
            // vertices in such an order that a CCW contour will add +1 to
            // the winding number of the region inside the contour.
            e._winding = 1
            e._Sym._winding = -1
        }
    }
    
    public func tessellate(windingRule: WindingRule, elementType: ElementType, polySize: Int) {
        tessellate(windingRule: windingRule, elementType: elementType, polySize: polySize, combineCallback: nil)
    }
    
    public func tessellate(windingRule: WindingRule, elementType: ElementType, polySize: Int, combineCallback: CombineCallback?) {
        _normal = Vector3.zero
        _vertices = nil
        _elements = nil

        _windingRule = windingRule
        _combineCallback = combineCallback

        guard let mesh = _mesh else {
            return
        }

        // Determine the polygon normal and project vertices onto the plane
        // of the polygon.
        projectPolygon()

        // ComputeInterior computes the planar arrangement specified
        // by the given contours, and further subdivides this arrangement
        // into regions.  Each region is marked "inside" if it belongs
        // to the polygon, according to the rule given by windingRule.
        // Each interior region is guaranteed be monotone.
        computeInterior()

        // If the user wants only the boundary contours, we throw away all edges
        // except those which separate the interior from the exterior.
        // Otherwise we tessellate all the regions marked "inside".
        if (elementType == ElementType.boundaryContours) {
            setWindingNumber(1, true)
        } else {
            tessellateInterior()
        }
        
        mesh.Check()
        
        if (elementType == ElementType.boundaryContours) {
            outputContours()
        } else {
            outputPolymesh(elementType, polySize)
        }
        
        mesh.OnFree()
        mesh.Reset()
        
        _mesh = nil
    }
}
