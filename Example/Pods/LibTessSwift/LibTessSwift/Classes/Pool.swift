//
//  Pool.swift
//  Pods
//
//  Created by Luiz Fernando Silva on 28/02/17.
//
//

/// Handy pooler
internal class Pool<Element> where Element: AnyObject & EmptyInitializable {
    
    /// Inner pool of objects
    fileprivate(set) internal var pool: ContiguousArray<Element> = []
    
    /// Collects all objects initialized by this pool
    fileprivate(set) internal var totalCreated: ContiguousArray<Element> = []
    
    /// Resets the contents of this pool
    func reset() {
        pool.removeAll()
        totalCreated.removeAll()
    }
    
    /// Pulls a new instance from this pool, creating it if necessary.
    func pull() -> Element {
        if(pool.count == 0) {
            let v = Element()
            
            totalCreated.append(v)
            
            return v
        }
        
        return pool.removeFirst()
    }
    
    /// Calls a given closure with a temporary value from this pool.
    /// Re-pooling the object on this pool during the call of this method is a
    /// programming error and should not be done.
    func withTemporary<U>(execute closure: (Element) throws -> (U)) rethrows -> U {
        let v = pull()
        defer {
            repool(v)
        }
        
        return try closure(v)
    }
    
    /// Repools a value for later retrieval with .pull()
    func repool(_ v: Element) {
        pool.append(v)
    }
}
