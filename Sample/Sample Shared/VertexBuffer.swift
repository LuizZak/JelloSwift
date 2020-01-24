//
//  Vertex.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 26/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import JelloSwift
import simd
import CoreGraphics

// MARK: Vector aliases -

// MARK: Vector3
typealias Vector3 = SIMD3<Float>

extension Vector3 {
    init(x: CGFloat, y: CGFloat, z: CGFloat) {
        self.init(x: Float(x), y: Float(y), z: Float(z))
    }
    
    init(x: Double, y: Double, z: Double) {
        self.init(x: Float(x), y: Float(y), z: Float(z))
    }
}

// MARK: Vector4
typealias Vector4 = SIMD4<Float>

extension Vector4 {
    init(x: Int, y: Int, z: Int, w: Int) {
        self.init(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
    }
    
    init(x: CGFloat, y: CGFloat, z: CGFloat, w: CGFloat) {
        self.init(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
    }
    
    init(x: Double, y: Double, z: Double, w: Double) {
        self.init(x: Float(x), y: Float(y), z: Float(z), w: Float(w))
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
    
    init(vector: Vector4) {
        self.vector = vector
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
    
    static func fromUIColor(_ color: Color) -> Color4 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return Color4(r: r, g: g, b: b, a: a)
    }
    
    func toUIColor() -> Color {
        return Color(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }
    
    static func fromUIntARGB(_ color: UInt) -> Color4 {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        a = CGFloat((color >> 24) & 0xff) / 255.0;
        r = CGFloat((color >> 16) & 0xff) / 255.0;
        g = CGFloat((color >> 8) & 0xff) / 255.0;
        b = CGFloat((color) & 0xff) / 255.0;
        
        return Color4(r: r, g: g, b: b, a: a)
    }
    
    func toUIntARGB() -> UInt {
        let ru: UInt = UInt(r * 255.0)
        let gu: UInt = UInt(g * 255.0)
        let bu: UInt = UInt(b * 255.0)
        let au: UInt = UInt(a * 255.0)
        
        return (au << 24) | (ru << 16) | (gu << 8) | bu
    }
}

extension Color4 {
    static let white = Color4(r: 1, g: 1, b: 1, a: 1)
    static let black = Color4(r: 0, g: 0, b: 0, a: 1)
    
    static let red = Color4(r: 1, g: 0, b: 0, a: 1)
    static let green = Color4(r: 0, g: 1, b: 0, a: 1)
    static let blue = Color4(r: 0, g: 0, b: 1, a: 1)
    
    static let yellow = Color4(r: 1, g: 1, b: 0, a: 1)
    static let magenta = Color4(r: 1, g: 0, b: 1, a: 1)
    static let cyan = Color4(r: 0, g: 1, b: 1, a: 1)
}

// MARK: -

/// Represents a Vertex of a 3D model.
/// Uses a float4 to define the color components, as well.
struct Vertex {
    var position: Vector3 = Vector3()
    var color: Color4 = Color4()
}

/// A paired vertex/index buffer, with identifiers coupled in
struct VertexBuffer {
    typealias VertexType = Vertex
    typealias IndexType = UInt32
    
    /// current color that will be added to all vertices that do not specify a
    /// color of their own
    var currentColor: UInt = 0xFFFFFFFF
    
    var vertices: [VertexType]
    var indices: [IndexType]
    
    /// The memory size of this vertex buffer's vertexBuffer property
    var vertexBufferSize: Int {
        return MemoryLayout<VertexType>.stride * vertices.count
    }
    
    /// The memory size of this vertex buffer's indices property
    var indexBufferSize: Int {
        return MemoryLayout<IndexType>.stride * indices.count
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
    
    init(vertices: [Vertex], indices: [UInt32]) {
        self.vertices = vertices
        self.indices = indices
    }
    
    /// Clears all the vertices and indices from this vertex buffer
    mutating func clearVertices() {
        vertices.removeAll(keepingCapacity: true)
        indices.removeAll(keepingCapacity: true)
    }
    
    /// Sets the color of all vertices to a specified color
    mutating func setVerticesColor(_ color: Color) {
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
        setVerticesColor(Color.fromUInt(color))
    }
    
    /// Merges the vertices and indices of another vertex array buffer into this
    /// one.
    /// This does not modify the handlers for this buffer.
    mutating func merge(with object: VertexBuffer) {
        let top = vertices.count
        
        // Increase incoming indices
        let newIndices = object.indices.map { $0 + UInt32(top) }
        
        vertices.append(contentsOf: object.vertices)
        indices.append(contentsOf: newIndices)
    }
    
    /// Adds a new vertex to this vertex buffer, with the current color component.
    @discardableResult
    mutating func addVertex(x: CGFloat, y: CGFloat) -> IndexType {
        return self.addVertex(x: x, y: y, color: currentColor)
    }
    
    /// Adds a new vertex to this vertex buffer, with the current color component.
    @discardableResult
    mutating func addVertex(x: JFloat, y: JFloat) -> IndexType {
        return self.addVertex(x: CGFloat(x), y: CGFloat(y), color: currentColor)
    }
    
    /// Adds a new vertex, specifying the color component to go along with it.
    @discardableResult
    mutating func addVertex(x: CGFloat, y: CGFloat, color: UInt) -> IndexType {
        return addVertex(Vector2(x: x, y: y), color: color)
    }
    
    /// Adds a new vertex, specifying the color component to go along with it.
    @discardableResult
    mutating func addVertex(x: JFloat, y: JFloat, color: UInt) -> IndexType {
        return addVertex(Vector2(x: CGFloat(x), y: CGFloat(y)), color: color)
    }
    
    /// Adds a new vertex, specifying the color component to go along with it.
    @discardableResult
    mutating func addVertex(_ vec: Vector2) -> IndexType {
        return addVertex(vec, color: currentColor)
    }
    
    /// Adds a new vertex, specifying the color component to go along with it.
    @discardableResult
    mutating func addVertex(_ vec: Vector2, color: UInt) -> IndexType {
        let a = (color >> 24) & 0xff
        let r = (color >> 16) & 0xff
        let g = (color >> 8) & 0xff
        let b = color & 0xff
        
        let position = Vector3(x: vec.x, y: vec.y, z: 0)
        let color = Color4(r: CFloat(r) / 255, g: CFloat(g) / 255, b: CFloat(b) / 255, a: CFloat(a) / 255)
        
        let vertex = Vertex(position: position, color: color)
        
        vertices.append(vertex)
        
        return IndexType(vertices.count - 1)
    }
    
    mutating func applyTransformation(_ matrix: float4x4) {
        for i in 0..<vertices.count {
            var vert = vertices[i]
            let result = SIMD4<Float>(vert.position.x, vert.position.y, vert.position.z, 1) * matrix
            vert.position = SIMD3<Float>(x: result.x, y: result.y, z: result.z)
            
            vertices[i] = vert
        }
    }
    
    mutating func addIndex(_ index: IndexType) {
        indices.append(index)
    }
    
    /// Adds a triangle to the indices by specifing three indexes on the buffer
    /// object.
    /// Make sure the provided values are within the bounds of the vertices
    /// array.
    mutating func addTriangleWithIndices(_ a: IndexType, _ b: IndexType, _ c: IndexType) {
        addIndex(a)
        addIndex(b)
        addIndex(c)
    }
    
    /// Creates a vertex buffer from a given set of vectors
    static func fromVectors(_ vectors: [Vector2]) -> VertexBuffer {
        
        let vertexes = vectors.map { vec -> Vertex in
            let pos = Vector3(x: vec.x, y: vec.y, z: 0)
            return Vertex(position: pos, color: .white)
        }
        
        let indices = Array(0..<IndexType(vectors.count))
        
        return VertexBuffer(vertices: vertexes, indices: indices)
    }
}
