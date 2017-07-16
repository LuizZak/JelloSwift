//
//  QuadTree.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 08/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Maximum number of nodes allowed in a single quad tree
let maxQuadTreeCount = 3

/// Maximum depth of a quadtree, quadtrees of this depth will not sub-divide further
let maxQuadTreeDepth = 6

/// Defines a protocol for objects that can be located in a 2D coordinate system
protocol QuadTreeItem {
    var bounds: AABB { get }
}

extension Body: QuadTreeItem {
    var bounds: AABB {
        return aabb
    }
}

/// A quad-tree that holds objects in a 2D space in recursive fashion, fit for
/// performing fast AABB queries.
class QuadTree<T: QuadTreeItem> {
    fileprivate(set) var storage: [T] = []
    fileprivate(set) var subtree: (northWest: QuadTree<T>, northEast: QuadTree<T>, southWest: QuadTree<T>, southEast: QuadTree<T>)?
    
    fileprivate(set) var aabb: AABB
    
    fileprivate(set) var depth: Int
    
    /// Gets the total number of items, recursively, for this quad tree
    var itemCount: Int {
        var c = storage.count
        if let subtree = subtree {
            c += subtree.northEast.itemCount
            c += subtree.northWest.itemCount
            c += subtree.southEast.itemCount
            c += subtree.northWest.itemCount
        }
        
        return c
    }
    
    convenience init(aabb: AABB) {
        self.init(aabb: aabb, depth: 0)
    }
    
    fileprivate init(aabb: AABB, depth: Int) {
        self.aabb = aabb
        self.depth = depth
        
        storage.reserveCapacity(maxQuadTreeCount)
    }
    
    /// Adds an item to this AABB- returning a value specifying if the object was
    /// added (it intersects w/ this AABB) or not.
    @discardableResult
    func insert(_ value: T) -> Bool {
        if(!aabb.intersects(value.bounds)) {
            return false
        }
        
        if(storage.count < maxQuadTreeCount || depth >= maxQuadTreeDepth) {
            storage.append(value)
            return true
        }
        
        let subtree = subdivided()
        let quadrants = [subtree.northWest, subtree.northEast, subtree.southWest, subtree.southEast]
        
        for quad in quadrants {
            if(quad.aabb.contains(value.bounds) && quad.insert(value)) {
                return true
            }
        }
        
        storage.append(value)
        
        return true
    }
    
    func subdivided() -> (northWest: QuadTree<T>, northEast: QuadTree<T>, southWest: QuadTree<T>, southEast: QuadTree<T>) {
        if let subtree = subtree {
            return subtree
        }
        
        // Create the quads now
        let middle = (aabb.minimum + aabb.maximum) / 2
        
        let nw = AABB(min: aabb.minimum, max: middle)
        let ne = AABB(min: Vector2(x: middle.x, y: aabb.minimum.y), max: Vector2(x: aabb.maximum.x, y: middle.y))
        let sw = AABB(min: Vector2(x: aabb.minimum.x, y: middle.y), max: Vector2(x: middle.x, y: aabb.maximum.y))
        let se = AABB(min: middle, max: aabb.maximum)
        
        let newSub = (QuadTree<T>(aabb: nw, depth: depth + 1), QuadTree<T>(aabb: ne, depth: depth + 1), QuadTree<T>(aabb: sw, depth: depth + 1), QuadTree<T>(aabb: se, depth: depth + 1))
        
        subtree = newSub
        
        return newSub
    }
    
    /// Clears all items/subnodes in this quadtree.
    func clear() {
        storage = []
        subtree = nil
    }
    
    /// Queries an AABB region returning all items that intersect w/ it.
    func queryAABB(_ aabb: AABB) -> [T] {
        var out: [T] = []
        
        innerQueryAABB(aabb, out: &out)
        
        return out
    }
    
    fileprivate func innerQueryAABB(_ aabb: AABB, out: inout [T]) {
        if(!self.aabb.intersects(aabb)) {
            return
        }
        
        for value in storage {
            if(aabb.intersects(value.bounds)) {
                out.append(value)
            }
        }
        
        if let subtree = subtree {
            subtree.northWest.innerQueryAABB(aabb, out: &out)
            subtree.northEast.innerQueryAABB(aabb, out: &out)
            subtree.southWest.innerQueryAABB(aabb, out: &out)
            subtree.southEast.innerQueryAABB(aabb, out: &out)
        }
    }
    
    /// Recursively queries the given AABB, calling the specified closure for every
    /// object intersecting the AABB's bounds.
    func queryAABB(_ aabb: AABB, with closure: (T) -> Void) {
        if(!self.aabb.intersects(aabb)) {
            return
        }
        
        for value in storage {
            if(aabb.intersects(value.bounds)) {
                closure(value)
            }
        }
        
        if let subtree = subtree {
            subtree.northWest.queryAABB(aabb, with: closure)
            subtree.northEast.queryAABB(aabb, with: closure)
            subtree.southWest.queryAABB(aabb, with: closure)
            subtree.southEast.queryAABB(aabb, with: closure)
        }
    }
}

extension QuadTree where T: Equatable {
    
    /// Removes an item from this quadtree, making sure to flatten sub-trees in
    /// case they can be flattened (item count becomes less than `maxQuadTreeCount`).
    func remove(_ value: T) -> Bool {
        for (i, item) in storage.enumerated() {
            if(item == value) {
                storage.remove(at: i)
                return true
            }
        }
        
        // Try removing from children nodes
        guard let sub = subtree else {
            return false
        }
        
        if(!sub.northWest.remove(value) && !sub.northEast.remove(value) && !sub.southWest.remove(value) && !sub.southEast.remove(value)) {
            return false
        }
        // If we got here, one of the sub-trees deleted an object - run through each subtree and verify whether the subtrees have
        // few enough items to lift to this quad-tree, if so, absorb the contents of the sub-nodes and remove them after
        if(sub.northWest.subtree != nil || sub.northEast.subtree != nil || sub.southWest.subtree != nil || sub.southEast.subtree == nil) {
            return true
        }
        
        if(storage.count + sub.northWest.storage.count + sub.northEast.storage.count + sub.southWest.storage.count + sub.southEast.storage.count < maxQuadTreeCount) {
            storage += sub.northWest.storage
            storage += sub.northEast.storage
            storage += sub.southWest.storage
            storage += sub.southEast.storage
            
            self.subtree = nil
        }
        
        return true
    }
}
