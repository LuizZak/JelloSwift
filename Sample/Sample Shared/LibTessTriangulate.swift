//
//  LibTessTriangulate.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 28/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import JelloSwift
import LibTessSwift

class LibTessTriangulate {
    
    static let tess = TessC()!
    
    /// Triangulates a set of vertices using LibTessSwift
    static func process(polygon: [Vector2]) throws -> (vertices: [Vector2], indices: [Int])? {
        
        // Try a simple triangulation, and fallback to libtess if it fails
        if let simple = Triangulate.processIndices(polygon: polygon) {
            return (polygon, simple)
        }
        
        let polySize = 3
        
        let contour = polygon.map {
            CVector3(x: TESSreal($0.x), y: TESSreal($0.y), z: 0.0)
        }
        
        tess.addContour(contour)
        
        let (vertices, elements) = try tess.tessellate(windingRule: .evenOdd,
                                                       elementType: .polygons,
                                                       polySize: polySize)
        
        var result: [Vector2] = []
        var indices: [Int] = []
        
        for vertex in vertices {
            result.append(Vector2(x: vertex.x, y: vertex.y))
        }
        
        for i in 0..<tess.elementCount {
            for j in 0..<polySize {
                let index = elements[i * polySize + j]
                if index == -1 {
                    continue
                }
                indices.append(index)
            }
        }
        
        return (result, indices)
    }
}
