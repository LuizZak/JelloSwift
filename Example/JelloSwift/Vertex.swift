//
//  Vertex.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 26/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import JelloSwift
import simd
import OpenGLES

// MARK: Vector aliases -

// MARK: Vector3
typealias Vector3 = float3

extension Vector3 {
    
    init(x: CGFloat, y: CGFloat, z: CGFloat) {
        self = float3(x: Float(x), y: Float(y), z: Float(z))
    }
    
    init(x: Double, y: Double, z: Double) {
        self = float3(x: Float(x), y: Float(y), z: Float(z))
    }
}

// MARK: Vector4
typealias Vector4 = packed_float4

extension Vector4 {
    
    init(x: Int, y: Int, z: Int, w: Int) {
        self = packed_float4(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
    }
    
    init(x: CGFloat, y: CGFloat, z: CGFloat, w: CGFloat) {
        self = packed_float4(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
    }
    
    init(x: Double, y: Double, z: Double, w: Double) {
        self = packed_float4(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
    }
}

/// An aliased set of colors, abstraced over a Vector4 container
struct Color4 {
    var vector: Vector4
    
    var r: CGFloat {
        get { return CGFloat(vector.x) }
        set { vector.x = Float(newValue) }
    }
    
    var g: CGFloat {
        get { return CGFloat(vector.y) }
        set { vector.y = Float(newValue) }
    }
    
    var b: CGFloat {
        get { return CGFloat(vector.z) }
        set { vector.z = Float(newValue) }
    }
    
    var a: CGFloat {
        get { return CGFloat(vector.w) }
        set { vector.w = Float(newValue) }
    }
    
    init() {
        vector = Vector4()
    }
    
    init(r: Int, g: Int, b: Int, a: Int) {
        vector = Vector4(x: r, y: g, z: b, w: a)
    }
    
    init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        vector = Vector4(x: r, y: g, z: b, w: a)
    }
    
    init(r: Float, g: Float, b: Float, a: Float) {
        vector = Vector4(x: r, y: g, z: b, w: a)
    }
    
    init(r: Double, g: Double, b: Double, a: Double) {
        vector = Vector4(x: Float(r), y: Float(g), z: Float(b), w: Float(a))
    }
    
    static func fromUIColor(_ color: UIColor) -> Color4 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return Color4(r: r, g: g, b: b, a: a)
    }
    
    func toUIColor() -> UIColor {
        return UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }
}

// MARK: -

/// Represents a Vertex of a 3D model.
/// Uses a float4 to define the color components, as well.
struct Vertex {
    
    /// Offset, in memory, of the 'color' field on this Vertex
    static var colorOffset: Int { return MemoryLayout<Vector3>.size }
    
    var position: Vector3
    var color: Color4
}

/// Represents a vertex array object, and an acompanying vertex buffer object
struct VertexArrayObject {
    var vao: GLuint
    var buffer: VertexBuffer
}

/// A paired vertex/index buffer, with identifiers coupled in
struct VertexBuffer {
    var indexBuffer: GLuint = 0
    var vertexBuffer: GLuint = 0
    
    /// current color that will be added to all vertices that do not specify a
    /// color of their own
    var currentColor: UInt = 0xFFFFFFFF
    
    var vertices: [Vertex]
    var indices: [GLuint]
    
    /// The memory size of this vertex buffer's vertexBuffer property
    var vertexBufferSize: Int {
        return MemoryLayout<Vertex>.size * vertices.count
    }
    
    /// The memory size of this vertex buffer's indices property
    var indexBufferSize: Int {
        return MemoryLayout<GLuint>.size * indices.count
    }
    
    /// Gets or sets the vertex at a given index
    subscript(index: Int) -> Vertex {
        get { return vertices[index] }
        set { vertices[index] = newValue }
    }
    
    /// Initializes an empty vertex buffer object
    init() {
        vertices = []
        indices = []
    }
    
    init(capacity: Int) {
        vertices = []
        indices = []
        
        vertices.reserveCapacity(capacity)
        indices.reserveCapacity(capacity)
    }
    
    init(vertices: [Vertex], indices: [GLuint]) {
        self.vertices = vertices
        self.indices = indices
    }
    
    /// Sets the color of all vertices to a specified color
    mutating func setVerticesColor(_ color: UIColor) {
        setVerticesColor(.fromUIColor(color))
    }
    
    /// Sets the color of all vertices to a specified color
    mutating func setVerticesColor(_ color: Color4) {
        for i in 0..<vertices.count {
            vertices[i].color = color
        }
    }
    
    /// Sets the color of all vertices to a specified color
    mutating func setVerticesColor(_ color: UInt) {
        setVerticesColor(UIColor.fromUInt(color))
    }
    
    /// Merges the vertices and indices of another vertex array buffer into this
    /// one.
    /// This does not modify the handlers for this buffer.
    mutating func merge(with object: VertexBuffer) {
        let top = vertices.count
        
        // Increase incoming indices
        let newIndices = object.indices.map { $0 + GLuint(top) }
        
        vertices.append(contentsOf: object.vertices)
        indices.append(contentsOf: newIndices)
    }
    
    /// Adds a new vertex to this vertex buffer, with the current color component.
    @discardableResult
    mutating func addVertex(x: CGFloat, y: CGFloat) -> Int {
        return self.addVertex(x: x, y: y, color: currentColor)
    }
    
    /// Adds a new vertex to this vertex buffer, with the current color component.
    @discardableResult
    mutating func addVertex(x: JFloat, y: JFloat) -> Int {
        return self.addVertex(x: CGFloat(x), y: CGFloat(y), color: currentColor)
    }
    
    /// Adds a new vertex, specifying the color component to go along with it.
    @discardableResult
    mutating func addVertex(x: CGFloat, y: CGFloat, color: UInt) -> Int {
        return addVertex(Vector2(x: x, y: y), color: color)
    }
    
    /// Adds a new vertex, specifying the color component to go along with it.
    @discardableResult
    mutating func addVertex(x: JFloat, y: JFloat, color: UInt) -> Int {
        return addVertex(Vector2(x: CGFloat(x), y: CGFloat(y)), color: color)
    }
    
    /// Adds a new vertex, specifying the color component to go along with it.
    @discardableResult
    mutating func addVertex(_ vec: Vector2) -> Int {
        return addVertex(vec, color: currentColor)
    }
    
    /// Adds a new vertex, specifying the color component to go along with it.
    @discardableResult
    mutating func addVertex(_ vec: Vector2, color: UInt) -> Int {
        let a = (color >> 24) & 0xff
        let r = (color >> 16) & 0xff
        let g = (color >> 8) & 0xff
        let b = color & 0xff
        
        let color = Color4(r: CFloat(r) / 255, g: CFloat(g) / 255, b: CFloat(b) / 255, a: CFloat(a) / 255)
        
        vertices.append(Vertex(position: Vector3(x: CFloat(vec.x), y: CFloat(vec.y), z: 0), color: color))
        return vertices.count - 1
    }
    
    mutating func applyTransformation(_ matrix: float4x4) {
        for i in 0..<vertices.count {
            var vert = vertices[i]
            let result = float4(vert.position.x, vert.position.y, vert.position.z, 1) * matrix
            vert.position = float3(x: result.x, y: result.y, z: result.z)
            
            vertices[i] = vert
        }
    }
    
    mutating func addIndice(_ indice: Int) {
        indices.append(GLuint(indice))
    }
    
    /// Adds a triangle to the indices by specifing three indexes on the buffer
    /// object.
    /// Make sure the provided values are within the bounds of the vertices
    /// array.
    mutating func addTriangleAtIndexes(_ a: Int, _ b: Int, _ c: Int) {
        indices.append(GLuint(a))
        indices.append(GLuint(b))
        indices.append(GLuint(c))
    }
    
    /// Clears all the vertices and indices from this vertex buffer
    mutating func clearVertices() {
        vertices.removeAll(keepingCapacity: true)
        indices.removeAll(keepingCapacity: true)
    }
    
    /// Creates a vertex buffer from a given set of vectors
    static func fromVectors(_ vectors: [Vector2]) -> VertexBuffer {
        
        let vertexes = vectors.map {
            Vertex(position: Vector3(x: CFloat($0.x), y: CFloat($0.y), z: 0), color: Color4(r: 1, g: 1, b: 1, a: 1))
        }
        
        let indices = Array(0..<GLuint(vectors.count))
        
        return VertexBuffer(vertices: vertexes, indices: indices)
    }
}
