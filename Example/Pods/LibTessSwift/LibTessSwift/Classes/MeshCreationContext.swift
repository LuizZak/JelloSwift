//
//  MeshCreationContext.swift
//  Pods
//
//  Created by Luiz Fernando Silva on 28/02/17.
//
//

/// Caches and manages information that is used during mesh generation
internal final class MeshCreationContext {
    
    private var _poolFaces = Pool<MeshUtils.Face>()
    private var _poolEdges = Pool<MeshUtils.Edge>()
    private var _poolVertices = Pool<MeshUtils.Vertex>()
    
    deinit {
        free()
    }
    
    func free() {
        for created in _poolFaces.totalCreated {
            created.Reset()
        }
        for created in _poolEdges.totalCreated {
            created.Reset()
        }
        for created in _poolVertices.totalCreated {
            created.Reset()
        }
        
        _poolFaces.reset()
        _poolEdges.reset()
        _poolVertices.reset()
    }
    
    func createFace() -> MeshUtils.Face {
        return _poolFaces.pull()
    }
    func resetFace(_ face: MeshUtils.Face) {
        _poolFaces.repool(face)
    }
    
    func createEdgePair() -> (pair: MeshUtils.EdgePair, e: MeshUtils.Edge, eSym: MeshUtils.Edge) {
        let e = createEdge()
        let eSym = createEdge()
        
        var pair = MeshUtils.EdgePair()
        pair._e = e
        pair._e?._pair = pair
        pair._eSym = eSym
        pair._eSym?._pair = pair
        
        return (pair, e, eSym)
    }
    
    func createEdge() -> MeshUtils.Edge {
        return _poolEdges.pull()
    }
    func resetEdge(_ edge: MeshUtils.Edge) {
        _poolEdges.repool(edge)
    }
    
    func createVertex() -> MeshUtils.Vertex {
        return _poolVertices.pull()
    }
    func resetVertex(_ vertex: MeshUtils.Vertex) {
        _poolVertices.repool(vertex)
    }
    
    /// <summary>
    /// MakeEdge creates a new pair of half-edges which form their own loop.
    /// No vertex or face structures are allocated, but these must be assigned
    /// before the current edge operation is completed.
    /// </summary>
    public func MakeEdge(_ eNext: MeshUtils.Edge) -> MeshUtils.Edge {
        var eNext = eNext
        
        let (_, e, eSym) = createEdgePair()
        
        // Make sure eNext points to the first edge of the edge pair
        MeshUtils.Edge.EnsureFirst(e: &eNext)
        
        // Insert in circular doubly-linked list before eNext.
        // Note that the prev pointer is stored in Sym->next.
        let ePrev = eNext._Sym?._next
        eSym._next = ePrev
        ePrev?._Sym?._next = e
        e._next = eNext
        eNext._Sym?._next = eSym
        
        e._Sym = eSym
        e._Onext = e
        e._Lnext = eSym
        e._Org = nil
        e._Lface = nil
        e._winding = 0
        e._activeRegion = nil
        
        eSym._Sym = e
        eSym._Onext = eSym
        eSym._Lnext = e
        eSym._Org = nil
        eSym._Lface = nil
        eSym._winding = 0
        eSym._activeRegion = nil
        
        return e
    }
    
    /// <summary>
    /// MakeVertex( eOrig, vNext ) attaches a new vertex and makes it the
    /// origin of all edges in the vertex loop to which eOrig belongs. "vNext" gives
    /// a place to insert the new vertex in the global vertex list. We insert
    /// the new vertex *before* vNext so that algorithms which walk the vertex
    /// list will not see the newly created vertices.
    /// </summary>
    public func MakeVertex(_ eOrig: MeshUtils.Edge, _ vNext: MeshUtils.Vertex) {
        let vNew = createVertex()
        
        // insert in circular doubly-linked list before vNext
        let vPrev = vNext._prev
        vNew._prev = vPrev
        vPrev?._next = vNew
        vNew._next = vNext
        vNext._prev = vNew
        
        vNew._anEdge = eOrig
        // leave coords, s, t undefined
        
        // fix other edges on this vertex loop
        var e: MeshUtils.Edge? = eOrig
        repeat {
            e?._Org = vNew
            e = e?._Onext
        } while (e !== eOrig)
    }
    
    /// <summary>
    /// MakeFace( eOrig, fNext ) attaches a new face and makes it the left
    /// face of all edges in the face loop to which eOrig belongs. "fNext" gives
    /// a place to insert the new face in the global face list. We insert
    /// the new face *before* fNext so that algorithms which walk the face
    /// list will not see the newly created faces.
    /// </summary>
    public func MakeFace(_ eOrig: MeshUtils.Edge, _ fNext: MeshUtils.Face) {
        let fNew = createFace()
        
        // insert in circular doubly-linked list before fNext
        let fPrev = fNext._prev
        fNew._prev = fPrev
        fPrev?._next = fNew
        fNew._next = fNext
        fNext._prev = fNew
        
        fNew._anEdge = eOrig
        fNew._marked = false
        
        // The new face is marked "inside" if the old one was. This is a
        // convenience for the common case where a face has been split in two.
        fNew._inside = fNext._inside
        
        // fix other edges on this face loop
        
        unowned(unsafe) var edp = eOrig
        repeat {
            edp._Lface = fNew
            edp = edp._Lnext
        } while (edp !== eOrig)
    }
    
    /// <summary>
    /// KillEdge( eDel ) destroys an edge (the half-edges eDel and eDel->Sym),
    /// and removes from the global edge list.
    /// </summary>
    public func KillEdge(_ eDel: MeshUtils.Edge) {
        // Half-edges are allocated in pairs, see EdgePair above
        var eDel = eDel
        MeshUtils.Edge.EnsureFirst(e: &eDel)
        
        // delete from circular doubly-linked list
        let eNext = eDel._next
        let ePrev = eDel._Sym?._next
        eNext?._Sym?._next = ePrev
        ePrev?._Sym?._next = eNext
        
        eDel._pair = nil
        
        resetEdge(eDel)
    }
    
    /// <summary>
    /// KillVertex( vDel ) destroys a vertex and removes it from the global
    /// vertex list. It updates the vertex loop to point to a given new vertex.
    /// </summary>
    public func KillVertex(_ vDel: MeshUtils.Vertex, _ newOrg: MeshUtils.Vertex?) {
        let eStart = vDel._anEdge
        
        // change the origin of all affected edges
        var e: MeshUtils.Edge? = eStart
        repeat {
            e?._Org = newOrg
            e = e?._Onext
        } while (e !== eStart)
        
        // delete from circular doubly-linked list
        let vPrev = vDel._prev
        let vNext = vDel._next
        vNext?._prev = vPrev
        vPrev?._next = vNext
        
        resetVertex(vDel)
    }
    
    /// <summary>
    /// KillFace( fDel ) destroys a face and removes it from the global face
    /// list. It updates the face loop to point to a given new face.
    /// </summary>
    public func KillFace(_ fDel: MeshUtils.Face, _ newLFace: MeshUtils.Face?) {
        let eStart = fDel._anEdge
        
        // change the left face of all affected edges
        var e: MeshUtils.Edge? = eStart
        repeat {
            e?._Lface = newLFace
            e = e?._Lnext
        } while (e !== eStart)
        
        // delete from circular doubly-linked list
        let fPrev = fDel._prev
        let fNext = fDel._next
        fNext?._prev = fPrev
        fPrev?._next = fNext
        
        resetFace(fDel)
    }
}
