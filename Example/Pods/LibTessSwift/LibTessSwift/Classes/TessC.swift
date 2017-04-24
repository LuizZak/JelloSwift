//
//  TessC.swift
//  Pods
//
//  Created by Luiz Fernando Silva on 01/03/17.
//
//

import Foundation
import simd

public enum WindingRule: Int, CustomStringConvertible {
    case evenOdd
    case nonZero
    case positive
    case negative
    case absGeqTwo
    
    public var description: String {
        switch(self) {
        case .evenOdd:
            return "evenOdd"
        case .nonZero:
            return "nonZero"
        case .positive:
            return "positive"
        case .negative:
            return "negative"
        case .absGeqTwo:
            return "absGeqTwo"
        }
    }
}

public enum ElementType: Int {
    case polygons
    case connectedPolygons
    case boundaryContours
}

public enum ContourOrientation {
    case original
    case clockwise
    case counterClockwise
}

/// Wraps the low-level C libtess2 library in a nice interface for Swift
public class TessC {
    
    var memoryPool: MemPool?
    var mem: UnsafeMutablePointer<UInt8>?
    var ma: TESSalloc?
    
    /// TESStesselator* tess
    var tess: UnsafeMutablePointer<Tesselator>
    
    /// List of vertices tesselated.
    /// Is nil, until a tesselation is performed.
    public var vertices: [CVector3]?
    
    /// List of elements tesselated.
    /// Is nil, until a tesselation is performed.
    public var elements: [Int]?
    
    /// Number of vertices present.
    /// Is 0, until a tesselation is performed.
    public var vertexCount: Int = 0
    
    /// Number of elements present
    /// Is 0, until a tesselation is performed.
    public var elementCount: Int = 0
    
    /// Tries to init this tesselator
    /// Optionally specifies whether to use memory pooling, and the memory size
    /// of the pool.
    /// This can be usefull for cases of constrained memory usage, and reduces
    /// overhead of repeated malloc/free calls
    public init?(usePooling: Bool = false, poolSize: Int = 1024 * 1024 * 10) {
        if(usePooling) {
            mem = malloc(poolSize).assumingMemoryBound(to: UInt8.self)
            
            memoryPool = MemPool(buf: mem!, cap: poolSize, size: 0)
            
            ma = TESSalloc(memalloc: { poolAlloc(userData: $0, size: $1) },
                           memrealloc: nil,
                           memfree: { poolFree(userData: $0, ptr: $1) },
                           userData: &memoryPool!, meshEdgeBucketSize: 0,
                           meshVertexBucketSize: 0, meshFaceBucketSize: 0,
                           dictNodeBucketSize: 0, regionBucketSize: 0,
                           extraVertices: 256)
            
            guard let tess = Tesselator.create(allocator: &ma!) else {
                // Free memory
                free(mem!)
                
                // Tesselator failed to initialize
                print("Failed to initialize tesselator")
                return nil
            }
            
            self.tess = tess
        } else {
            guard let tess = Tesselator.create(allocator: nil) else {
                // Tesselator failed to initialize
                print("Failed to initialize tesselator")
                return nil
            }
            
            self.tess = tess
        }
    }
    
    deinit {
        // Free tesselator
        tess.pointee.destroy()
        if let mem = mem {
            free(mem)
        }
    }
    
    public func addContour(_ vertices: [CVector3], _ forceOrientation: ContourOrientation = .original) {
        var vertices = vertices
        
        var reverse = false
        if (forceOrientation != ContourOrientation.original) {
            let area = signedArea(vertices)
            reverse = (forceOrientation == ContourOrientation.clockwise && area < 0.0) || (forceOrientation == ContourOrientation.counterClockwise && area > 0.0)
        }
        
        if(reverse) {
            vertices = vertices.reversed()
        }
        
        tess.pointee.addContour(size: 3, pointer: vertices, stride: CInt(MemoryLayout<CVector3>.size), count: CInt(vertices.count))
    }
    
    /// Tesselates a given series of points, and returns the final vector
    /// representation and its indices.
    /// Can throw errors, in case tesselation failed.
    @discardableResult
    public func tessellate(windingRule: WindingRule, elementType: ElementType, polySize: Int) throws -> (vertices: [CVector3], indices: [Int]) {
        
        if(tess.pointee.tesselate(windingRule: Int32(windingRule.rawValue), elementType: Int32(elementType.rawValue), polySize: Int32(polySize), vertexSize: 3, normal: nil) == 0) {
            throw TessError.tesselationFailed
        }
        
        // Fetch tesselation out
        tessGetElements(tess)
        let verts = tess.pointee.vertices!
        let elems = tess.pointee.elements!
        let nverts = Int(tess.pointee.vertexCount)
        let nelems = Int(tess.pointee.elementCount)
        
        var output: [CVector3] = []
        var indicesOut: [Int] = []
        
        for i in 0..<nverts {
            let x = verts[i * 3]
            let y = verts[i * 3 + 1]
            let z = verts[i * 3 + 2]
            
            output.append(CVector3(x: x, y: y, z: z))
        }
        
        for i in 0..<nelems {
            let p = elems.advanced(by: i * polySize)
            for j in 0..<polySize where p[j] != ~TESSindex() {
                indicesOut.append(Int(p[j]))
            }
        }
        
        vertexCount = nverts
        elementCount = nelems
        
        vertices = output
        elements = indicesOut
        
        return (output, indicesOut)
    }
    
    private func signedArea(_ vertices: [CVector3]) -> TESSreal {
        var area: TESSreal = 0.0
        
        for i in 0..<vertices.count {
            let v0 = vertices[i]
            let v1 = vertices[(i + 1) % vertices.count]
            
            area += v0.x * v1.y
            area -= v0.y * v1.x
        }
        
        return 0.5 * area
    }
    
    public enum TessError: Error {
        /// Error when a tessTesselate() call fails
        case tesselationFailed
    }
}
