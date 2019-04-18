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
open class TessC {
    
    /// Memory pooler - simple struct that is used as `userData` by the `TESSalloc`
    /// methods.
    /// Nil, if not using memory pooling.
    var memoryPool: MemPool?
    /// Pointer to raw memory buffer used for memory pool - nil, if not using 
    /// memory pooling.
    var mem: UnsafeMutablePointer<UInt8>?
    /// Allocator - nil, if not using memory pooling.
    var ma: TESSalloc?
    
    /// TESStesselator* tess
    var _tess: UnsafeMutablePointer<Tesselator>
    
    /// The pointer to the Tesselator struct that represents the underlying
    /// libtess2 tesselator.
    ///
    /// This pointer wraps the dynamically allocated underlying pointer, and is
    /// automatically deallocated on deinit, so you don't need to (nor should!)
    /// manually deallocate it, or keep it alive externally longer than the life
    /// time of a `TessC` instance.
    ///
    /// If you want to manually manage a libtess2's tesselator lifetime, use
    /// `Tesselator.create(allocator:)` and `Tesselator.destroy(_:Tesselator)` 
    /// instead.
    public var tess: UnsafePointer<Tesselator> {
        return UnsafePointer(_tess)
    }
    
    /// List of vertices tesselated.
    /// Is nil, until a tesselation (CVector3-variant) is performed.
    public var vertices: [CVector3]?
    
    /// Raw list of vertices tesselated.
    /// Is nil, until a tesselation (any variant) is performed.
    public var verticesRaw: [TESSreal]?
    
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
            
            self._tess = tess
        } else {
            guard let tess = Tesselator.create(allocator: nil) else {
                // Tesselator failed to initialize
                print("Failed to initialize tesselator")
                return nil
            }
            
            self._tess = tess
        }
    }
    
    deinit {
        // Free tesselator
        _tess.pointee.destroy()
        if let mem = mem {
            free(mem)
        }
    }
    
    /// A raw access to libtess2's tessAddContour, providing the contour from
    /// a specified array, containing raw indexes.
    ///
    /// Stride of contour that is passed down is:
    ///
    ///     MemoryLayout<T>.size * vertexSize
    ///
    /// (`vertexSize` is 3 for `.vertex3`, 2 for `.vertex2`).
    ///
    /// - Parameters:
    ///   - vertices: Raw vertices to add
    ///   - vertexSize: Size of vertices. This will change the size of the stride
    /// when adding the contour, as well.
    open func addContourRaw(_ vertices: [TESSreal], vertexSize: VertexSize) {
        if(vertices.count % vertexSize.rawValue != 0) {
            print("Warning: Vertices array provided has wrong count! Expected multiple of \(vertexSize.rawValue), received \(vertices.count).")
        }
        
        _tess.pointee.addContour(size: Int32(vertexSize.rawValue),
                                 pointer: vertices,
                                 stride: CInt(MemoryLayout<TESSreal>.size * vertexSize.rawValue),
                                 count: CInt(vertices.count / vertexSize.rawValue))
    }
    
    /// Adds a new contour using a specified set of 3D points.
    ///
    /// - Parameters:
    ///   - vertices: Vertices to add to the tesselator buffer.
    ///   - forceOrientation: Whether to force orientation of contour in some way.
    /// Defaults to `.original`, which adds contour as-is with no modifications
    /// to orientation.
    open func addContour(_ vertices: [CVector3], _ forceOrientation: ContourOrientation = .original) {
        var vertices = vertices
        
        // Re-orientation
        if (forceOrientation != .original) {
            let area = signedArea(vertices)
            if (forceOrientation == .clockwise && area < 0.0) || (forceOrientation == .counterClockwise && area > 0.0) {
                vertices = vertices.reversed()
            }
        }
        
        _tess.pointee.addContour(size: 3, pointer: vertices, stride: CInt(MemoryLayout<CVector3>.size), count: CInt(vertices.count))
    }
    
    /// Tesselates a given series of points, and returns the final vector
    /// representation and its indices.
    /// Can throw errors, in case tesselation failed.
    ///
    /// This variant of `tesselate` returns the raw set of vertices on `vertices`.
    /// `vertices` will always be `% vertexSize` count of elements.
    ///
    /// - Parameters:
    ///   - windingRule: Winding rule for tesselation.
    ///   - elementType: Type of elements contained in the contours buffer.
    ///   - polySize: Defines maximum vertices per polygons if output is polygons.
    ///   - vertexSize: Defines the vertex size to fetch with the output. Specifying
    /// .vertex2 on inputs that have 3 coordinates will zero 'z' values of all
    /// coordinates.
    @discardableResult
    open func tessellateRaw(windingRule: WindingRule, elementType: ElementType, polySize: Int, vertexSize: VertexSize = .vertex3) throws -> (vertices: [TESSreal], indices: [Int]) {
        
        if(_tess.pointee.tesselate(windingRule: Int32(windingRule.rawValue), elementType: Int32(elementType.rawValue), polySize: Int32(polySize), vertexSize: Int32(vertexSize.rawValue), normal: nil) == 0) {
            throw TessError.tesselationFailed
        }
        
        // Fetch tesselation out
        tessGetElements(_tess)
        let verts = _tess.pointee.vertices!
        let elems = _tess.pointee.elements!
        let nverts = Int(_tess.pointee.vertexCount)
        let nelems = Int(_tess.pointee.elementCount)
        
        let stride: Int = vertexSize.rawValue
        
        var output: [TESSreal] = Array(repeating: 0, count: nverts * stride)
        output.withUnsafeMutableBufferPointer { body -> Void in
            body.baseAddress?.assign(from: verts, count: nverts * stride)
        }
        var indicesOut: [Int] = []
        
        for i in 0..<nelems {
            let p = elems.advanced(by: i * polySize)
            for j in 0..<polySize where p[j] != ~TESSindex() {
                indicesOut.append(Int(p[j]))
            }
        }
        
        verticesRaw = output
        vertexCount = nverts
        elementCount = nelems
        
        elements = indicesOut
        
        return (output, indicesOut)
    }
    
    /// Tesselates a given series of points, and returns the final vector
    /// representation and its indices.
    /// Can throw errors, in case tesselation failed.
    ///
    /// This variant of `tesselate` automatically compacts vertices into an array
    /// of CVector3 values before returning.
    ///
    /// - Parameters:
    ///   - windingRule: Winding rule for tesselation.
    ///   - elementType: Type of elements contained in the contours buffer.
    ///   - polySize: Defines maximum vertices per polygons if output is polygons.
    ///   - vertexSize: Defines the vertex size to fetch with the output. Specifying
    /// .vertex2 on inputs that have 3 coordinates will zero 'z' values of all
    /// coordinates.
    @discardableResult
    open func tessellate(windingRule: WindingRule, elementType: ElementType, polySize: Int, vertexSize: VertexSize = .vertex3) throws -> (vertices: [CVector3], indices: [Int]) {
        
        let (verts, i) = try tessellateRaw(windingRule: windingRule, elementType: elementType, polySize: polySize, vertexSize: vertexSize)
        
        var output: [CVector3] = []
        output.reserveCapacity(vertexCount)
        
        let stride: Int = vertexSize.rawValue
        for i in 0..<vertexCount {
            let x = verts[i * stride]
            let y = verts[i * stride + 1]
            let z = vertexSize == .vertex3 ? verts[i * stride + 2] : 0
            
            output.append(CVector3(x: x, y: y, z: z))
        }
        
        vertices = output
        
        return (output, i)
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
    
    /// Used to specify vertex sizing to underlying tesselator.
    ///
    /// - vertex2: Vertices have 2 coordinates.
    /// - vertex3: Vertices have 3 coordinates.
    public enum VertexSize: Int {
        case vertex2 = 2
        case vertex3 = 3
    }
}
