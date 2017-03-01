//
//  LibTessTriangulate.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 28/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import JelloSwift
import LibTessSwift

class LibTessTriangulate {
    
    /// Triangulates a set of vertices using LibTessSwift
    static func process(polygon: [Vector2]) -> (vertices: [Vector2], indices: [Int])? {
        let tess = Tess()
        let polySize = 3
        
        let contour = polygon.map {
            ContourVertex(Position: LibTessSwift.Vector3(x: Double($0.x), y: Double($0.y), z: Double(0.0)))
        }
        
        tess.addContour(contour)
        
        tess.tessellate(windingRule: .evenOdd, elementType: .polygons, polySize: polySize)
        
        var result: [Vector2] = []
        var indices: [Int] = []
        
        for vertex in tess.vertices {
            result.append(Vector2(vertex.position.x, vertex.position.y))
        }
        
        for i in 0..<tess.elementCount
        {
            for j in 0..<polySize
            {
                let index = tess.elements[i * polySize + j];
                if (index == -1) {
                    continue;
                }
                indices.append(index)
                let v = Vector2(tess.vertices[index].position.x, tess.vertices[index].position.y)
                
                result.append(v)
            }
        }
        
        return (result, indices)
    }
}
