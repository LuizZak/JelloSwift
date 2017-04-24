//
//  MemPool.swift
//  Pods
//
//  Created by Luiz Fernando Silva on 15/04/17.
//
//

func stdAlloc(userData: UnsafeMutableRawPointer?, size: Int) -> UnsafeMutableRawPointer {
    let allocated = userData?.assumingMemoryBound(to: Int.self)
    allocated?.pointee += size
    
    return malloc(size)
}

func stdFree(userData: UnsafeMutableRawPointer?, ptr: UnsafeMutableRawPointer) {
    free(ptr)
}

struct MemPool {
    var buf: UnsafeMutablePointer<UInt8>
    var cap: Int
    var size: Int
}

func poolAlloc(userData: UnsafeMutableRawPointer?, size: Int) -> UnsafeMutableRawPointer? {
    guard let userData = userData else {
        NSLog("Missing pool allocator's MemPool parameter")
        return nil
    }
    
    let pool = userData.assumingMemoryBound(to: MemPool.self)
    
    let size = (size+0x7) & ~0x7;
    
    if (pool.pointee.size + size < pool.pointee.cap)
    {
        let ptr = pool.pointee.buf + pool.pointee.size;
        pool.pointee.size += size
        
        return UnsafeMutableRawPointer(ptr)
    }
    
    NSLog("out of mem: %d < %d!\n", pool.pointee.size + size, pool.pointee.cap)
    
    return nil
}

func poolFree(userData: UnsafeMutableRawPointer?, ptr: UnsafeMutableRawPointer) {
    // Not used
}
