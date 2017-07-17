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
struct QuadTree<T: AnyObject & QuadTreeItem> {
    fileprivate(set) var elements: ContiguousArray<T> = []
    fileprivate(set) var subtree: ContiguousArray<QuadTree<T>> = []
    
    fileprivate(set) var aabb: AABB
    
    fileprivate(set) var depth: Int
    
    /// Gets the total number of items, recursively, for this quad tree
    var itemCount: Int {
        return subtree.reduce(0) { $0 + $1.itemCount }
    }
    
    init(aabb: AABB) {
        self.init(aabb: aabb, depth: 0)
    }
    
    fileprivate init(aabb: AABB, depth: Int) {
        self.aabb = aabb
        self.depth = depth
    }
    
    /// Adds an item to this AABB- returning a value specifying if the object was
    /// added (it intersects w/ this AABB) or not.
    @discardableResult
    mutating func insert(_ value: T) -> Bool {
        if(!aabb.intersects(value.bounds)) {
            return false
        }
        
        if(elements.count < maxQuadTreeCount || depth >= maxQuadTreeDepth) {
            elements.append(value)
            return true
        }
        
        subdivided()
        for i in 0..<subtree.count {
            if(!subtree[i].aabb.contains(value.bounds)) {
                continue
            }
            
            if(subtree[i].insert(value)) {
                return true
            }
        }
        
        elements.append(value)
        
        return true
    }
    
    @discardableResult
    mutating func subdivided() -> ContiguousArray<QuadTree<T>> {
        if subtree.count > 0 {
            return subtree
        }
        
        // Create the quads now
        let middle = (aabb.minimum + aabb.maximum) / 2
        
        let nw = AABB(min: aabb.minimum, max: middle)
        let ne = AABB(min: Vector2(x: middle.x, y: aabb.minimum.y), max: Vector2(x: aabb.maximum.x, y: middle.y))
        let sw = AABB(min: Vector2(x: aabb.minimum.x, y: middle.y), max: Vector2(x: middle.x, y: aabb.maximum.y))
        let se = AABB(min: middle, max: aabb.maximum)
        
        subtree = [
            QuadTree<T>(aabb: nw, depth: depth + 1),
            QuadTree<T>(aabb: ne, depth: depth + 1),
            QuadTree<T>(aabb: sw, depth: depth + 1),
            QuadTree<T>(aabb: se, depth: depth + 1)
        ]
        
        return subtree
    }
    
    /// Clears all items/subnodes in this quadtree.
    mutating func clear() {
        elements = []
        subtree.removeAll(keepingCapacity: true)
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
        
        for value in elements {
            if(aabb.intersects(value.bounds)) {
                out.append(value)
            }
        }
        
        for sub in subtree {
            sub.innerQueryAABB(aabb, out: &out)
        }
    }
    
    /// Recursively queries the given AABB, calling the specified closure for every
    /// object intersecting the AABB's bounds.
    func queryAABB(_ aabb: AABB, with closure: (T) -> Void) {
        guard self.aabb.intersects(aabb) else {
            return
        }
        
        for value in elements {
            if aabb.intersects(value.bounds) {
                closure(value)
            }
        }
        
        for sub in subtree {
            sub.queryAABB(aabb, with: closure)
        }
    }
}

extension QuadTree where T: Equatable {
    
    /// Removes an item from this quadtree, making sure to flatten sub-trees in
    /// case they can be flattened (item count becomes less than `maxQuadTreeCount`).
    mutating func remove(_ value: T) -> Bool {
        for (i, item) in elements.enumerated() {
            if(item == value) {
                elements.remove(at: i)
                return true
            }
        }
        
        // Try removing from children nodes
        guard subtree.count > 0 else {
            return false
        }
        
        var rem = false
        for i in 0..<subtree.count {
            if(subtree[i].remove(value)) {
                rem = true
                break
            }
        }
        
        if(!rem) {
            return false
        }
        
        // If we got here, one of the sub-trees deleted an object - run through 
        // each subtree and verify whether the subtrees have few enough items to
        // lift to this quad-tree, if so, absorb the contents of the sub-nodes 
        // and remove them after
        for sub in subtree {
            if(sub.subtree.count > 0) {
                return true
            }
        }
        
        if(itemCount < maxQuadTreeCount) {
            for sub in subtree {
                elements += sub.elements
            }
            
            self.subtree.removeAll(keepingCapacity: true)
        }
        
        return true
    }
}
