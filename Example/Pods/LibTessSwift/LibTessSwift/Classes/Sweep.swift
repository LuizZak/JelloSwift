//
//  Sweep.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 27/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

extension Tess {
    
    internal final class ActiveRegion: EmptyInitializable {
        internal var _eUp: MeshUtils.Edge!
        internal weak var _nodeUp: Node<ActiveRegion>!
        internal var _windingNumber: Int = 0
        internal var _inside: Bool = false, _sentinel: Bool = false, _dirty: Bool = false, _fixUpperEdge: Bool = false
    }

    private func RegionBelow(_ reg: ActiveRegion) -> ActiveRegion! {
        return reg._nodeUp.Prev?.Key
    }

    private func RegionAbove(_ reg: ActiveRegion) -> ActiveRegion! {
        return reg._nodeUp.Next?.Key
    }
    
    
    /// <summary>
    /// Both edges must be directed from right to left (this is the canonical
    /// direction for the upper edge of each region).
    /// 
    /// The strategy is to evaluate a "t" value for each edge at the
    /// current sweep line position, given by tess->event. The calculations
    /// are designed to be very stable, but of course they are not perfect.
    /// 
    /// Special case: if both edge destinations are at the sweep event,
    /// we sort the edges by slope (they would otherwise compare equally).
    /// </summary>
    private func EdgeLeq(_ reg1: ActiveRegion, _ reg2: ActiveRegion) -> Bool {
        let e1 = reg1._eUp!
        let e2 = reg2._eUp!

        if (e1._Dst === _event) {
            if (e2._Dst === _event) {
                // Two edges right of the sweep line which meet at the sweep event.
                // Sort them by slope.
                if (Geom.VertLeq(e1._Org, e2._Org)) {
                    return Geom.EdgeSign(e2._Dst, e1._Org, e2._Org) <= 0.0
                }
                return Geom.EdgeSign(e1._Dst, e2._Org, e1._Org) >= 0.0
            }
            return Geom.EdgeSign(e2._Dst, _event!, e2._Org) <= 0.0
        }
        if (e2._Dst === _event) {
            return Geom.EdgeSign(e1._Dst, _event!, e1._Org) >= 0.0
        }

        // General case - compute signed distance *from* e1, e2 to event
        let t1 = Geom.EdgeEval(e1._Dst, _event!, e1._Org)
        let t2 = Geom.EdgeEval(e2._Dst, _event!, e2._Org)
        return (t1 >= t2)
    }

    
    private func DeleteRegion(_ reg: ActiveRegion) {
        if (reg._fixUpperEdge) {
            // It was created with zero winding number, so it better be
            // deleted with zero winding number (ie. it better not get merged
            // with a real edge).
            assert(reg._eUp._winding == 0)
        }
        reg._eUp._activeRegion = nil
        _dict.Remove(node: reg._nodeUp)
        
        reg._eUp = nil
        reg._windingNumber = 0
        reg._nodeUp = nil
        
        _regionsPool.repool(reg)
    }

    /// <summary>
    /// Replace an upper edge which needs fixing (see ConnectRightVertex).
    /// </summary>
    private func FixUpperEdge(_ reg: ActiveRegion, _ newEdge: MeshUtils.Edge) {
        assert(reg._fixUpperEdge)
        _mesh.Delete(reg._eUp)
        reg._fixUpperEdge = false
        reg._eUp = newEdge
        newEdge._activeRegion = reg
    }

    private func TopLeftRegion(_ reg: ActiveRegion) -> ActiveRegion! {
        var reg = reg
        let org = reg._eUp._Org

        // Find the region above the uppermost edge with the same origin
        repeat {
            reg = RegionAbove(reg)!
        } while (reg._eUp._Org === org)

        // If the edge above was a temporary edge introduced by ConnectRightVertex,
        // now is the time to fix it.
        if (reg._fixUpperEdge) {
            let e = _mesh.Connect(RegionBelow(reg)._eUp._Sym, reg._eUp._Lnext)
            FixUpperEdge(reg, e)
            reg = RegionAbove(reg)!
        }

        return reg
    }
    
    private func TopRightRegion(_ reg: ActiveRegion) -> ActiveRegion! {
        var reg = reg
        let dst = reg._eUp._Dst

        // Find the region above the uppermost edge with the same destination
        repeat {
            reg = RegionAbove(reg)!
        } while (reg._eUp._Dst === dst)

        return reg
    }

    /// <summary>
    /// Add a new active region to the sweep line, *somewhere* below "regAbove"
    /// (according to where the new edge belongs in the sweep-line dictionary).
    /// The upper edge of the new region will be "eNewUp".
    /// Winding number and "inside" flag are not updated.
    /// </summary>
    private func AddRegionBelow(_ regAbove: ActiveRegion, _ eNewUp: MeshUtils.Edge) -> ActiveRegion {
        let regNew = _regionsPool.pull()

        regNew._eUp = eNewUp
        regNew._nodeUp = _dict.InsertBefore(node: regAbove._nodeUp, key: regNew)
        regNew._fixUpperEdge = false
        regNew._sentinel = false
        regNew._dirty = false

        eNewUp._activeRegion = regNew

        return regNew
    }

    private func ComputeWinding(_ reg: ActiveRegion) {
        reg._windingNumber = RegionAbove(reg)._windingNumber + reg._eUp._winding
        reg._inside = Geom.IsWindingInside(_windingRule, reg._windingNumber)
    }
    
    /// <summary>
    /// Delete a region from the sweep line. This happens when the upper
    /// and lower chains of a region meet (at a vertex on the sweep line).
    /// The "inside" flag is copied to the appropriate mesh face (we could
    /// not do this before -- since the structure of the mesh is always
    /// changing, this face may not have even existed until now).
    /// </summary>
    private func FinishRegion(_ reg: ActiveRegion) {
        let e = reg._eUp
        let f = e!._Lface!

        f._inside = reg._inside
        f._anEdge = e
        
        DeleteRegion(reg)
    }

    /// <summary>
    /// We are given a vertex with one or more left-going edges.  All affected
    /// edges should be in the edge dictionary.  Starting at regFirst->eUp,
    /// we walk down deleting all regions where both edges have the same
    /// origin vOrg.  At the same time we copy the "inside" flag from the
    /// active region to the face, since at this point each face will belong
    /// to at most one region (this was not necessarily true until this point
    /// in the sweep).  The walk stops at the region above regLast; if regLast
    /// is nil we walk as far as possible.  At the same time we relink the
    /// mesh if necessary, so that the ordering of edges around vOrg is the
    /// same as in the dictionary.
    /// </summary>
    @discardableResult
    private func FinishLeftRegions(_ regFirst: ActiveRegion, _ regLast: ActiveRegion?) -> MeshUtils.Edge {
        var regPrev = regFirst
        var ePrev = regFirst._eUp!
        
        while (regPrev !== regLast) {
            regPrev._fixUpperEdge = false	// placement was OK
            let reg = RegionBelow(regPrev)!
            var e = reg._eUp!
            if (e._Org !== ePrev._Org) {
                if (!reg._fixUpperEdge) {
                    // Remove the last left-going edge.  Even though there are no further
                    // edges in the dictionary with this origin, there may be further
                    // such edges in the mesh (if we are adding left edges to a vertex
                    // that has already been processed).  Thus it is important to call
                    // FinishRegion rather than just DeleteRegion.
                    FinishRegion(regPrev)
                    break
                }
                // If the edge below was a temporary edge introduced by
                // ConnectRightVertex, now is the time to fix it.
                e = _mesh.Connect(ePrev._Lprev, e._Sym)
                FixUpperEdge(reg, e)
            }

            // Relink edges so that ePrev.Onext == e
            if (ePrev._Onext !== e) {
                _mesh.Splice(e._Oprev, e)
                _mesh.Splice(ePrev, e)
            }
            FinishRegion(regPrev) // may change reg.eUp
            ePrev = reg._eUp
            regPrev = reg
        }

        return ePrev
    }

    /// <summary>
    /// Purpose: insert right-going edges into the edge dictionary, and update
    /// winding numbers and mesh connectivity appropriately.  All right-going
    /// edges share a common origin vOrg.  Edges are inserted CCW starting at
    /// eFirst; the last edge inserted is eLast.Oprev.  If vOrg has any
    /// left-going edges already processed, then eTopLeft must be the edge
    /// such that an imaginary upward vertical segment from vOrg would be
    /// contained between eTopLeft.Oprev and eTopLeft; otherwise eTopLeft
    /// should be nil.
    /// </summary>
    private func AddRightEdges(_ regUp: ActiveRegion, _ eFirst: MeshUtils.Edge, _ eLast: MeshUtils.Edge, _ eTopLeft: MeshUtils.Edge?, cleanUp: Bool) {
        var eTopLeft = eTopLeft
        var firstTime = true

        var e = eFirst
        
        repeat {
            assert(Geom.VertLeq(e._Org, e._Dst))
            _=AddRegionBelow(regUp, e._Sym)
            e = e._Onext
        } while (e !== eLast)
        
        // Walk *all* right-going edges from e.Org, in the dictionary order,
        // updating the winding numbers of each region, and re-linking the mesh
        // edges to match the dictionary ordering (if necessary).
        if (eTopLeft == nil) {
            eTopLeft = RegionBelow(regUp)?._eUp._Rprev
        }

        var regPrev = regUp
        var reg = RegionBelow(regPrev)
        var ePrev = eTopLeft!
        while (true) {
            reg = RegionBelow(regPrev)
            e = reg!._eUp._Sym
            if (e._Org !== ePrev._Org) { break }
            
            if (e._Onext !== ePrev) {
                // Unlink e from its current position, and relink below ePrev
                _mesh.Splice(e._Oprev, e)
                _mesh.Splice(ePrev._Oprev, e)
            }
            // Compute the winding number and "inside" flag for the new regions
            reg!._windingNumber = regPrev._windingNumber - e._winding
            reg!._inside = Geom.IsWindingInside(_windingRule, reg!._windingNumber)
            
            // Check for two outgoing edges with same slope -- process these
            // before any intersection tests (see example in tessComputeInterior).
            regPrev._dirty = true
            if (!firstTime && CheckForRightSplice(regPrev)) {
                Geom.AddWinding(e, ePrev)
                DeleteRegion(regPrev)
                _mesh.Delete(ePrev)
            }
            firstTime = false
            regPrev = reg!
            ePrev = e
        }
        regPrev._dirty = true
        assert(regPrev._windingNumber - e._winding == reg!._windingNumber)
        
        if (cleanUp) {
            // Check for intersections between newly adjacent edges.
            WalkDirtyRegions(regPrev)
        }
    }
    
    /// <summary>
    /// Two vertices with idential coordinates are combined into one.
    /// e1.Org is kept, while e2.Org is discarded.
    /// </summary>
    private func SpliceMergeVertices(_ e1: MeshUtils.Edge, _ e2: MeshUtils.Edge) {
        _mesh.Splice(e1, e2)
    }

    /// <summary>
    /// Find some weights which describe how the intersection vertex is
    /// a linear combination of "org" and "dest".  Each of the two edges
    /// which generated "isect" is allocated 50% of the weight; each edge
    /// splits the weight between its org and dst according to the
    /// relative distance to "isect".
    /// </summary>
    private func VertexWeights(_ isect: MeshUtils.Vertex, _ org: MeshUtils.Vertex, _ dst: MeshUtils.Vertex, _ w0: inout CGFloat, _ w1: inout CGFloat) {
        let t1 = Geom.VertL1dist(u: org, v: isect)
        let t2 = Geom.VertL1dist(u: dst, v: isect)

        w0 = (t2 / (t1 + t2)) / 2.0
        w1 = (t1 / (t1 + t2)) / 2.0

        isect._coords.X += w0 * org._coords.X + w1 * dst._coords.X
        isect._coords.Y += w0 * org._coords.Y + w1 * dst._coords.Y
        isect._coords.Z += w0 * org._coords.Z + w1 * dst._coords.Z
    }

    /// <summary>
    /// We've computed a new intersection point, now we need a "data" pointer
    /// from the user so that we can refer to this new vertex in the
    /// rendering callbacks.
    /// </summary>
    private func GetIntersectData(_ isect: MeshUtils.Vertex, _ orgUp: MeshUtils.Vertex, _ dstUp: MeshUtils.Vertex, _ orgLo: MeshUtils.Vertex, _ dstLo: MeshUtils.Vertex) {
        isect._coords = Vec3.Zero
        
        var w0: CGFloat = 0, w1: CGFloat = 0, w2: CGFloat = 0, w3: CGFloat = 0
        
        VertexWeights(isect, orgUp, dstUp, &w0, &w1)
        VertexWeights(isect, orgLo, dstLo, &w2, &w3)

        if let callback = _combineCallback {
            isect._data = callback(
                isect._coords,
                [ orgUp._data, dstUp._data, orgLo._data, dstLo._data ],
                [ w0, w1, w2, w3 ]
            )
        }
    }

    /// <summary>
    /// Check the upper and lower edge of "regUp", to make sure that the
    /// eUp->Org is above eLo, or eLo->Org is below eUp (depending on which
    /// origin is leftmost).
    /// 
    /// The main purpose is to splice right-going edges with the same
    /// dest vertex and nearly identical slopes (ie. we can't distinguish
    /// the slopes numerically).  However the splicing can also help us
    /// to recover from numerical errors.  For example, suppose at one
    /// point we checked eUp and eLo, and decided that eUp->Org is barely
    /// above eLo.  Then later, we split eLo into two edges (eg. from
    /// a splice operation like this one).  This can change the result of
    /// our test so that now eUp->Org is incident to eLo, or barely below it.
    /// We must correct this condition to maintain the dictionary invariants.
    /// 
    /// One possibility is to check these edges for intersection again
    /// (ie. CheckForIntersect).  This is what we do if possible.  However
    /// CheckForIntersect requires that tess->event lies between eUp and eLo,
    /// so that it has something to fall back on when the intersection
    /// calculation gives us an unusable answer.  So, for those cases where
    /// we can't check for intersection, this routine fixes the problem
    /// by just splicing the offending vertex into the other edge.
    /// This is a guaranteed solution, no matter how degenerate things get.
    /// Basically this is a combinatorial solution to a numerical problem.
    /// </summary>
    @discardableResult
    private func CheckForRightSplice(_ regUp: ActiveRegion) -> Bool {
        let regLo = RegionBelow(regUp)!
        let eUp = regUp._eUp!
        let eLo = regLo._eUp!

        if (Geom.VertLeq(eUp._Org, eLo._Org)) {
            if (Geom.EdgeSign(eLo._Dst, eUp._Org, eLo._Org) > 0.0) {
                return false
            }

            // eUp.Org appears to be below eLo
            if (!Geom.VertEq(eUp._Org, eLo._Org)) {
                // Splice eUp._Org into eLo
                _mesh.SplitEdge(eLo._Sym)
                _mesh.Splice(eUp, eLo._Oprev)
                regUp._dirty = true
                regLo._dirty = true
            } else if (eUp._Org !== eLo._Org) {
                // merge the two vertices, discarding eUp.Org
                _pq.Remove(eUp._Org._pqHandle)
                SpliceMergeVertices(eLo._Oprev, eUp)
            }
        } else {
            if (Geom.EdgeSign(eUp._Dst, eLo._Org, eUp._Org) < 0.0) {
                return false
            }

            // eLo.Org appears to be above eUp, so splice eLo.Org into eUp
            RegionAbove(regUp)._dirty = true
            regUp._dirty = true
            _mesh.SplitEdge(eUp._Sym)
            _mesh.Splice(eLo._Oprev, eUp)
        }
        return true
    }
    
    /// <summary>
    /// Check the upper and lower edge of "regUp", to make sure that the
    /// eUp->Dst is above eLo, or eLo->Dst is below eUp (depending on which
    /// destination is rightmost).
    /// 
    /// Theoretically, this should always be true.  However, splitting an edge
    /// into two pieces can change the results of previous tests.  For example,
    /// suppose at one point we checked eUp and eLo, and decided that eUp->Dst
    /// is barely above eLo.  Then later, we split eLo into two edges (eg. from
    /// a splice operation like this one).  This can change the result of
    /// the test so that now eUp->Dst is incident to eLo, or barely below it.
    /// We must correct this condition to maintain the dictionary invariants
    /// (otherwise new edges might get inserted in the wrong place in the
    /// dictionary, and bad stuff will happen).
    /// 
    /// We fix the problem by just splicing the offending vertex into the
    /// other edge.
    /// </summary>
    private func CheckForLeftSplice(_ regUp: ActiveRegion) -> Bool {
        let regLo = RegionBelow(regUp)!
        let eUp = regUp._eUp!
        let eLo = regLo._eUp!

        assert(!Geom.VertEq(eUp._Dst, eLo._Dst))

        if (Geom.VertLeq(eUp._Dst, eLo._Dst)) {
            if (Geom.EdgeSign(eUp._Dst, eLo._Dst, eUp._Org) < 0.0) {
                return false
            }

            // eLo.Dst is above eUp, so splice eLo.Dst into eUp
            RegionAbove(regUp)._dirty = true
            regUp._dirty = true
            let e = _mesh.SplitEdge(eUp)
            _mesh.Splice(eLo._Sym, e)
            e._Lface._inside = regUp._inside
        } else {
            if (Geom.EdgeSign(eLo._Dst, eUp._Dst, eLo._Org) > 0.0) {
                return false
            }

            // eUp.Dst is below eLo, so splice eUp.Dst into eLo
            regUp._dirty = true
            regLo._dirty = true
            let e = _mesh.SplitEdge(eLo)
            _mesh.Splice(eUp._Lnext, eLo._Sym)
            e._Rface._inside = regUp._inside
        }
        return true
    }

    /// <summary>
    /// Check the upper and lower edges of the given region to see if
    /// they intersect.  If so, create the intersection and add it
    /// to the data structures.
    /// 
    /// Returns TRUE if adding the new intersection resulted in a recursive
    /// call to AddRightEdges(); in this case all "dirty" regions have been
    /// checked for intersections, and possibly regUp has been deleted.
    /// </summary>
    @discardableResult
    private func CheckForIntersect(_ regUp: ActiveRegion) -> Bool {
        var regUp = regUp
        var regLo = RegionBelow(regUp)!
        var eUp = regUp._eUp!
        var eLo = regLo._eUp!
        let orgUp = eUp._Org!
        let orgLo = eLo._Org!
        let dstUp = eUp._Dst!
        let dstLo = eLo._Dst!

        assert(!Geom.VertEq(dstLo, dstUp))
        assert(Geom.EdgeSign(dstUp, _event, orgUp) <= 0.0)
        assert(Geom.EdgeSign(dstLo, _event, orgLo) >= 0.0)
        assert(orgUp !== _event && orgLo !== _event)
        assert(!regUp._fixUpperEdge && !regLo._fixUpperEdge)

        if( orgUp === orgLo ) {
            // right endpoints are the same
            return false
        }

        let tMinUp = min(orgUp._t, dstUp._t)
        let tMaxLo = max(orgLo._t, dstLo._t)
        if( tMinUp > tMaxLo ) {
            // t ranges do not overlap
            return false
        }

        if (Geom.VertLeq(orgUp, orgLo)) {
            if (Geom.EdgeSign( dstLo, orgUp, orgLo ) > 0.0) {
                return false
            }
        } else {
            if (Geom.EdgeSign( dstUp, orgLo, orgUp ) < 0.0) {
                return false
            }
        }

        // At this point the edges intersect, at least marginally
        let isect = _mesh._context.createVertex()
        Geom.EdgeIntersect(o1: dstUp, d1: orgUp, o2: dstLo, d2: orgLo, v: isect)
        // The following properties are guaranteed:
        assert(min(orgUp._t, dstUp._t) <= isect._t)
        assert(isect._t <= max(orgLo._t, dstLo._t))
        assert(min(dstLo._s, dstUp._s) <= isect._s)
        assert(isect._s <= max(orgLo._s, orgUp._s))

        if (Geom.VertLeq(isect, _event)) {
            // The intersection point lies slightly to the left of the sweep line,
            // so move it until it''s slightly to the right of the sweep line.
            // (If we had perfect numerical precision, this would never happen
            // in the first place). The easiest and safest thing to do is
            // replace the intersection by tess._event.
            isect._s = _event._s
            isect._t = _event._t
        }
        // Similarly, if the computed intersection lies to the right of the
        // rightmost origin (which should rarely happen), it can cause
        // unbelievable inefficiency on sufficiently degenerate inputs.
        // (If you have the test program, try running test54.d with the
        // "X zoom" option turned on).
        let orgMin = Geom.VertLeq(orgUp, orgLo) ? orgUp : orgLo
        if (Geom.VertLeq(orgMin, isect)) {
            isect._s = orgMin._s
            isect._t = orgMin._t
        }

        if (Geom.VertEq(isect, orgUp) || Geom.VertEq(isect, orgLo)) {
            // Easy case -- intersection at one of the right endpoints
            CheckForRightSplice(regUp)
            return false
        }

        if (   (!Geom.VertEq(dstUp, _event)
            && Geom.EdgeSign(dstUp, _event, isect) >= 0.0)
            || (!Geom.VertEq(dstLo, _event)
            && Geom.EdgeSign(dstLo, _event, isect) <= 0.0)) {
            // Very unusual -- the new upper or lower edge would pass on the
            // wrong side of the sweep event, or through it. This can happen
            // due to very small numerical errors in the intersection calculation.
            if (dstLo === _event) {
                // Splice dstLo into eUp, and process the new region(s)
                _mesh.SplitEdge(eUp._Sym)
                _mesh.Splice(eLo._Sym, eUp)
                regUp = TopLeftRegion(regUp)
                eUp = RegionBelow(regUp)._eUp
                FinishLeftRegions(RegionBelow(regUp), regLo)
                AddRightEdges(regUp, eUp._Oprev, eUp, eUp, cleanUp: true)
                return true
            }
            if( dstUp === _event ) {
                /* Splice dstUp into eLo, and process the new region(s) */
                _mesh.SplitEdge(eLo._Sym)
                _mesh.Splice(eUp._Lnext, eLo._Oprev)
                regLo = regUp
                regUp = TopRightRegion(regUp)
                let e = RegionBelow(regUp)._eUp._Rprev
                regLo._eUp = eLo._Oprev
                eLo = FinishLeftRegions(regLo, nil)
                AddRightEdges(regUp, eLo._Onext, eUp._Rprev, e, cleanUp: true)
                return true
            }
            // Special case: called from ConnectRightVertex. If either
            // edge passes on the wrong side of tess._event, split it
            // (and wait for ConnectRightVertex to splice it appropriately).
            if (Geom.EdgeSign( dstUp, _event, isect ) >= 0.0) {
                RegionAbove(regUp)._dirty = true
                regUp._dirty = true
                _mesh.SplitEdge(eUp._Sym)
                eUp._Org._s = _event._s
                eUp._Org._t = _event._t
            }
            if (Geom.EdgeSign(dstLo, _event, isect) <= 0.0) {
                regUp._dirty = true
                regLo._dirty = true
                _mesh.SplitEdge(eLo._Sym)
                eLo._Org._s = _event._s
                eLo._Org._t = _event._t
            }
            // leave the rest for ConnectRightVertex
            return false
        }

        // General case -- split both edges, splice into new vertex.
        // When we do the splice operation, the order of the arguments is
        // arbitrary as far as correctness goes. However, when the operation
        // creates a new face, the work done is proportional to the size of
        // the new face.  We expect the faces in the processed part of
        // the mesh (ie. eUp._Lface) to be smaller than the faces in the
        // unprocessed original contours (which will be eLo._Oprev._Lface).
        _mesh.SplitEdge(eUp._Sym)
        _mesh.SplitEdge(eLo._Sym)
        _mesh.Splice(eLo._Oprev, eUp)
        eUp._Org._s = isect._s
        eUp._Org._t = isect._t
        eUp._Org._pqHandle = _pq.Insert(eUp._Org)
        if (eUp._Org._pqHandle._handle == PQHandle.Invalid) {
            // TODO: Use a proper throw here
            fatalError("PQHandle should not be invalid")
            //throw new InvalidOperationException("PQHandle should not be invalid")
        }
        GetIntersectData(eUp._Org, orgUp, dstUp, orgLo, dstLo)
        RegionAbove(regUp)._dirty = true
        regUp._dirty = true
        regLo._dirty = true
        return false
    }

    /// <summary>
    /// When the upper or lower edge of any region changes, the region is
    /// marked "dirty".  This routine walks through all the dirty regions
    /// and makes sure that the dictionary invariants are satisfied
    /// (see the comments at the beginning of this file).  Of course
    /// new dirty regions can be created as we make changes to restore
    /// the invariants.
    /// </summary>
    private func WalkDirtyRegions(_ regUp: ActiveRegion) {
        
        var regUp: ActiveRegion! = regUp
        var regLo = RegionBelow(regUp)!
        var eUp: MeshUtils.Edge, eLo: MeshUtils.Edge

        while (true) {
            // Find the lowest dirty region (we walk from the bottom up).
            while (regLo._dirty) {
                regUp = regLo
                regLo = RegionBelow(regLo)
            }
            if (!regUp._dirty) {
                regLo = regUp
                regUp = RegionAbove( regUp )
                if(regUp == nil || !regUp._dirty) {
                    // We've walked all the dirty regions
                    return
                }
            }
            regUp._dirty = false
            eUp = regUp._eUp
            eLo = regLo._eUp
            
            if (eUp._Dst !== eLo._Dst) {
                // Check that the edge ordering is obeyed at the Dst vertices.
                if (CheckForLeftSplice(regUp)) {

                    // If the upper or lower edge was marked fixUpperEdge, then
                    // we no longer need it (since these edges are needed only for
                    // vertices which otherwise have no right-going edges).
                    if (regLo._fixUpperEdge) {
                        DeleteRegion(regLo)
                        _mesh.Delete(eLo)
                        regLo = RegionBelow(regUp)
                        eLo = regLo._eUp
                    } else if( regUp._fixUpperEdge ) {
                        DeleteRegion(regUp)
                        _mesh.Delete(eUp)
                        regUp = RegionAbove(regLo)
                        eUp = regUp._eUp
                    }
                }
            }
            
            if (eUp._Org !== eLo._Org) {
                if(
                    eUp._Dst !== eLo._Dst
                    && !regUp._fixUpperEdge && !regLo._fixUpperEdge
                    && (eUp._Dst === _event || eLo._Dst === _event)
                    ) {
                    // When all else fails in CheckForIntersect(), it uses tess._event
                    // as the intersection location. To make this possible, it requires
                    // that tess._event lie between the upper and lower edges, and also
                    // that neither of these is marked fixUpperEdge (since in the worst
                    // case it might splice one of these edges into tess.event, and
                    // violate the invariant that fixable edges are the only right-going
                    // edge from their associated vertex).
                    if (CheckForIntersect(regUp)) {
                        // WalkDirtyRegions() was called recursively; we're done
                        return
                    }
                } else {
                    // Even though we can't use CheckForIntersect(), the Org vertices
                    // may violate the dictionary edge ordering. Check and correct this.
                    CheckForRightSplice(regUp)
                }
            }
            if (eUp._Org === eLo._Org && eUp._Dst === eLo._Dst) {
                // A degenerate loop consisting of only two edges -- delete it.
                Geom.AddWinding(eLo, eUp)
                DeleteRegion(regUp)
                _mesh.Delete(eUp)
                regUp = RegionAbove(regLo)
            }
        }
    }
    
    /// <summary>
    /// Purpose: connect a "right" vertex vEvent (one where all edges go left)
    /// to the unprocessed portion of the mesh.  Since there are no right-going
    /// edges, two regions (one above vEvent and one below) are being merged
    /// into one.  "regUp" is the upper of these two regions.
    /// 
    /// There are two reasons for doing this (adding a right-going edge):
    ///  - if the two regions being merged are "inside", we must add an edge
    ///    to keep them separated (the combined region would not be monotone).
    ///  - in any case, we must leave some record of vEvent in the dictionary,
    ///    so that we can merge vEvent with features that we have not seen yet.
    ///    For example, maybe there is a vertical edge which passes just to
    ///    the right of vEvent; we would like to splice vEvent into this edge.
    /// 
    /// However, we don't want to connect vEvent to just any vertex.  We don''t
    /// want the new edge to cross any other edges; otherwise we will create
    /// intersection vertices even when the input data had no self-intersections.
    /// (This is a bad thing; if the user's input data has no intersections,
    /// we don't want to generate any false intersections ourselves.)
    /// 
    /// Our eventual goal is to connect vEvent to the leftmost unprocessed
    /// vertex of the combined region (the union of regUp and regLo).
    /// But because of unseen vertices with all right-going edges, and also
    /// new vertices which may be created by edge intersections, we don''t
    /// know where that leftmost unprocessed vertex is.  In the meantime, we
    /// connect vEvent to the closest vertex of either chain, and mark the region
    /// as "fixUpperEdge".  This flag says to delete and reconnect this edge
    /// to the next processed vertex on the boundary of the combined region.
    /// Quite possibly the vertex we connected to will turn out to be the
    /// closest one, in which case we won''t need to make any changes.
    /// </summary>
    private func ConnectRightVertex(_ regUp: ActiveRegion, _ eBottomLeft: MeshUtils.Edge) {
        var regUp = regUp
        var eBottomLeft = eBottomLeft
        var eTopLeft = eBottomLeft._Onext!
        let regLo = RegionBelow(regUp)!
        let eUp = regUp._eUp!
        let eLo = regLo._eUp!
        var degenerate = false

        if (eUp._Dst !== eLo._Dst) {
            CheckForIntersect(regUp)
        }

        // Possible new degeneracies: upper or lower edge of regUp may pass
        // through vEvent, or may coincide with new intersection vertex
        if (Geom.VertEq(eUp._Org, _event)) {
            _mesh.Splice(eTopLeft._Oprev, eUp)
            regUp = TopLeftRegion(regUp)!
            eTopLeft = RegionBelow(regUp)._eUp
            FinishLeftRegions(RegionBelow(regUp), regLo)
            degenerate = true
        }
        if (Geom.VertEq(eLo._Org, _event)) {
            _mesh.Splice(eBottomLeft, eLo._Oprev)
            eBottomLeft = FinishLeftRegions(regLo, nil)
            degenerate = true
        }
        if (degenerate) {
            AddRightEdges(regUp, eBottomLeft._Onext, eTopLeft, eTopLeft, cleanUp: true)
            return
        }

        // Non-degenerate situation -- need to add a temporary, fixable edge.
        // Connect to the closer of eLo.Org, eUp.Org.
        var eNew: MeshUtils.Edge
        if (Geom.VertLeq(eLo._Org, eUp._Org)) {
            eNew = eLo._Oprev
        } else {
            eNew = eUp
        }
        eNew = _mesh.Connect(eBottomLeft._Lprev, eNew)

        // Prevent cleanup, otherwise eNew might disappear before we've even
        // had a chance to mark it as a temporary edge.
        AddRightEdges(regUp, eNew, eNew._Onext, eNew._Onext, cleanUp: false)
        eNew._Sym._activeRegion._fixUpperEdge = true
        WalkDirtyRegions(regUp)
    }

    /// <summary>
    /// The event vertex lies exacty on an already-processed edge or vertex.
    /// Adding the new vertex involves splicing it into the already-processed
    /// part of the mesh.
    /// </summary>
    private func ConnectLeftDegenerate(_ regUp: ActiveRegion, _ vEvent: MeshUtils.Vertex) {
        let e = regUp._eUp!
        if (Geom.VertEq(e._Org, vEvent)) {
            // e.Org is an unprocessed vertex - just combine them, and wait
            // for e.Org to be pulled from the queue
            // C# : in the C version, there is a flag but it was never implemented
            // the vertices are before beginning the tesselation
            
            fatalError("Vertices should have been merged before")
            // TODO: Throw a proper error here
            //throw new InvalidOperationException("Vertices should have been merged before")
        }

        if (!Geom.VertEq(e._Dst, vEvent)) {
            // General case -- splice vEvent into edge e which passes through it
            _mesh.SplitEdge(e._Sym)
            if (regUp._fixUpperEdge) {
                // This edge was fixable -- delete unused portion of original edge
                _mesh.Delete(e._Onext)
                regUp._fixUpperEdge = false
            }
            _mesh.Splice(vEvent._anEdge, e)
            SweepEvent(vEvent)	// recurse
            return
        }

        // See above
        fatalError("Vertices should have been merged before")
        // TODO: Throw a proper error here
        //throw new InvalidOperationException("Vertices should have been merged before")
    }

    /// <summary>
    /// Purpose: connect a "left" vertex (one where both edges go right)
    /// to the processed portion of the mesh.  Let R be the active region
    /// containing vEvent, and let U and L be the upper and lower edge
    /// chains of R.  There are two possibilities:
    /// 
    /// - the normal case: split R into two regions, by connecting vEvent to
    ///   the rightmost vertex of U or L lying to the left of the sweep line
    /// 
    /// - the degenerate case: if vEvent is close enough to U or L, we
    ///   merge vEvent into that edge chain.  The subcases are:
    ///     - merging with the rightmost vertex of U or L
    ///     - merging with the active edge of U or L
    ///     - merging with an already-processed portion of U or L
    /// </summary>
    private func ConnectLeftVertex(_ vEvent: MeshUtils.Vertex) {
        
        // Get a pointer to the active region containing vEvent
        let regUp = _regionsPool.withTemporary { tmp -> ActiveRegion in
            tmp._eUp = vEvent._anEdge._Sym
            return _dict.Find(key: tmp).Key!
        }
        
        guard let regLo = RegionBelow(regUp) else {
            // This may happen if the input polygon is coplanar.
            return
        }
        let eUp = regUp._eUp!
        let eLo = regLo._eUp!
        
        // Try merging with U or L first
        if (Geom.EdgeSign(eUp._Dst, vEvent, eUp._Org) == 0.0) {
            ConnectLeftDegenerate(regUp, vEvent)
            return
        }
        
        // Connect vEvent to rightmost processed vertex of either chain.
        // e._Dst is the vertex that we will connect to vEvent.
        let reg = Geom.VertLeq(eLo._Dst, eUp._Dst) ? regUp : regLo

        if (regUp._inside || reg._fixUpperEdge) {
            var eNew: MeshUtils.Edge
            if (reg === regUp) {
                eNew = _mesh.Connect(vEvent._anEdge._Sym, eUp._Lnext)
            } else {
                eNew = _mesh.Connect(eLo._Dnext, vEvent._anEdge)._Sym
            }
            if (reg._fixUpperEdge) {
                FixUpperEdge(reg, eNew)
            } else {
                ComputeWinding(AddRegionBelow(regUp, eNew))
            }
            SweepEvent(vEvent)
        } else {
            // The new vertex is in a region which does not belong to the polygon.
            // We don't need to connect this vertex to the rest of the mesh.
            AddRightEdges(regUp, vEvent._anEdge, vEvent._anEdge, nil, cleanUp: true)
        }
    }

    /// <summary>
    /// Does everything necessary when the sweep line crosses a vertex.
    /// Updates the mesh and the edge dictionary.
    /// </summary>
    private func SweepEvent(_ vEvent: MeshUtils.Vertex) {
        _event = vEvent

        // Check if this vertex is the right endpoint of an edge that is
        // already in the dictionary. In this case we don't need to waste
        // time searching for the location to insert new edges.
        var e = vEvent._anEdge!
        while (e._activeRegion == nil) {
            e = e._Onext
            if (e === vEvent._anEdge) {
                // All edges go right -- not incident to any processed edges
                ConnectLeftVertex(vEvent)
                return
            }
        }
        
        // Processing consists of two phases: first we "finish" all the
        // active regions where both the upper and lower edges terminate
        // at vEvent (ie. vEvent is closing off these regions).
        // We mark these faces "inside" or "outside" the polygon according
        // to their winding number, and delete the edges from the dictionary.
        // This takes care of all the left-going edges from vEvent.
        let regUp = TopLeftRegion(e._activeRegion)!
        let reg = RegionBelow(regUp)!
        let eTopLeft = reg._eUp!
        let eBottomLeft = FinishLeftRegions(reg, nil)

        // Next we process all the right-going edges from vEvent. This
        // involves adding the edges to the dictionary, and creating the
        // associated "active regions" which record information about the
        // regions between adjacent dictionary edges.
        if (eBottomLeft._Onext === eTopLeft) {
            // No right-going edges -- add a temporary "fixable" edge
            ConnectRightVertex(regUp, eBottomLeft)
        } else {
            AddRightEdges(regUp, eBottomLeft._Onext, eTopLeft, eTopLeft, cleanUp: true)
        }
    }

    /// <summary>
    /// Make the sentinel coordinates big enough that they will never be
    /// merged with real input features.
    /// 
    /// We add two sentinel edges above and below all other edges,
    /// to avoid special cases at the top and bottom.
    /// </summary>
    private func AddSentinel(_ smin: CGFloat, _ smax: CGFloat, _ t: CGFloat) {
        let e = _mesh.MakeEdge()
        e._Org._s = smax
        e._Org._t = t
        e._Dst._s = smin
        e._Dst._t = t
        _event = e._Dst // initialize it
        
        let reg = _regionsPool.pull()
        reg._eUp = e
        reg._windingNumber = 0
        reg._inside = false
        reg._fixUpperEdge = false
        reg._sentinel = true
        reg._dirty = false
        reg._nodeUp = _dict.Insert(key: reg)
    }

    /// <summary>
    /// We maintain an ordering of edge intersections with the sweep line.
    /// This order is maintained in a dynamic dictionary.
    /// </summary>
    private func InitEdgeDict() {
        _dict = Dict<ActiveRegion>(leq: EdgeLeq)

        AddSentinel(-SentinelCoord, SentinelCoord, -SentinelCoord)
        AddSentinel(-SentinelCoord, SentinelCoord, +SentinelCoord)
    }

    private func DoneEdgeDict() {
        var fixedEdges = 0

        while let reg = _dict.Min()?.Key {
            // At the end of all processing, the dictionary should contain
            // only the two sentinel edges, plus at most one "fixable" edge
            // created by ConnectRightVertex().
            if (!reg._sentinel) {
                assert(reg._fixUpperEdge)
                fixedEdges += 1
                assert(fixedEdges == 1)
            }
            assert(reg._windingNumber == 0)
            DeleteRegion(reg)
        }

        _dict = nil
    }

    /// <summary>
    /// Remove zero-length edges, and contours with fewer than 3 vertices.
    /// </summary>
    private func RemoveDegenerateEdges() {
        var eHead = _mesh._eHead, eNext: MeshUtils.Edge, eLnext: MeshUtils.Edge
        
        // Can't use _mesh.forEachEdge due to a reassignment of the next edge
        // to step to
        var e = eHead._next!
        while e !== eHead {
            defer {
                e = eNext
            }
            
            eNext = e._next
            eLnext = e._Lnext

            if (Geom.VertEq(e._Org, e._Dst) && e._Lnext._Lnext !== e) {
                // Zero-length edge, contour has at least 3 edges

                SpliceMergeVertices(eLnext, e)	// deletes e.Org
                _mesh.Delete(e) // e is a self-loop
                e = eLnext
                eLnext = e._Lnext // Can't use _mesh.forEachEdge due to this reassignment
            }
            if (eLnext._Lnext === e) {
                // Degenerate contour (one or two edges)

                if (eLnext !== e) {
                    if (eLnext === eNext || eLnext === eNext._Sym) {
                        eNext = eNext._next
                    }
                    _mesh.Delete(eLnext)
                }
                if (e === eNext || e === eNext._Sym) {
                    eNext = eNext._next
                }
                _mesh.Delete(e)
            }
        }
    }

    /// <summary>
    /// Insert all vertices into the priority queue which determines the
    /// order in which vertices cross the sweep line.
    /// </summary>
    private func InitPriorityQ() {
        var vertexCount = 0
        
        _mesh.forEachVertex { v in
            vertexCount += 1
        }
        
        // Make sure there is enough space for sentinels.
        vertexCount += 8
        
        _pq = PriorityQueue<MeshUtils.Vertex>(vertexCount,  { Geom.VertLeq($0!, $1!) })
        
        _mesh.forEachVertex { v in
            v._pqHandle = _pq.Insert(v)
            if (v._pqHandle._handle == PQHandle.Invalid) {
                // TODO: Throw a proper error here
                fatalError("PQHandle should not be invalid")
                //throw new InvalidOperationException("PQHandle should not be invalid")
            }
        }
        _pq.Init()
    }

    private func DonePriorityQ() {
        _pq = nil
    }

    /// <summary>
    /// Delete any degenerate faces with only two edges.  WalkDirtyRegions()
    /// will catch almost all of these, but it won't catch degenerate faces
    /// produced by splice operations on already-processed edges.
    /// The two places this can happen are in FinishLeftRegions(), when
    /// we splice in a "temporary" edge produced by ConnectRightVertex(),
    /// and in CheckForLeftSplice(), where we splice already-processed
    /// edges to ensure that our dictionary invariants are not violated
    /// by numerical errors.
    /// 
    /// In both these cases it is *very* dangerous to delete the offending
    /// edge at the time, since one of the routines further up the stack
    /// will sometimes be keeping a pointer to that edge.
    /// </summary>
    private func RemoveDegenerateFaces() {
        _mesh.forEachFace { f in
            let e = f._anEdge!
            assert(e._Lnext !== e)
            
            if (e._Lnext._Lnext === e) {
                // A face with only two edges
                Geom.AddWinding(e._Onext, e)
                _mesh.Delete(e)
            }
        }
    }

    /// <summary>
    /// ComputeInterior computes the planar arrangement specified
    /// by the given contours, and further subdivides this arrangement
    /// into regions.  Each region is marked "inside" if it belongs
    /// to the polygon, according to the rule given by windingRule.
    /// Each interior region is guaranteed to be monotone.
    /// </summary>
    internal func computeInterior() {
        // Each vertex defines an event for our sweep line. Start by inserting
        // all the vertices in a priority queue. Events are processed in
        // lexicographic order, ie.
        // 
        // e1 < e2  iff  e1.x < e2.x || (e1.x == e2.x && e1.y < e2.y)
        RemoveDegenerateEdges()
        InitPriorityQ()
        RemoveDegenerateFaces()
        InitEdgeDict()

        var vNext: MeshUtils.Vertex?
        
        while let v = _pq.ExtractMin() {
            autoreleasepool {
                while (true) {
                    vNext = _pq.Minimum()
                    if (vNext == nil || !Geom.VertEq(vNext!, v)) {
                        break
                    }
                    
                    // Merge together all vertices at exactly the same location.
                    // This is more efficient than processing them one at a time,
                    // simplifies the code (see ConnectLeftDegenerate), and is also
                    // important for correct handling of certain degenerate cases.
                    // For example, suppose there are two identical edges A and B
                    // that belong to different contours (so without this code they would
                    // be processed by separate sweep events). Suppose another edge C
                    // crosses A and B from above. When A is processed, we split it
                    // at its intersection point with C. However this also splits C,
                    // so when we insert B we may compute a slightly different
                    // intersection point. This might leave two edges with a small
                    // gap between them. This kind of error is especially obvious
                    // when using boundary extraction (BoundaryOnly).
                    vNext = _pq.ExtractMin()
                    SpliceMergeVertices(v._anEdge, vNext!._anEdge)
                }
                SweepEvent(v)
            }
        }

        DoneEdgeDict()
        DonePriorityQ()

        RemoveDegenerateFaces()
        _mesh.Check()
    }
}
