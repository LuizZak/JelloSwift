//
//  Renderer.swift
//  Sample Shared
//
//  Created by Luiz Fernando Silva on 12/07/19.
//  Copyright © 2019 Luiz Fernando Silva. All rights reserved.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate {
    var multisampleLevel = 8
    
    public let metalDevice: MTLDevice!
    let metalCommandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MetalBuffer<VertexBuffer.VertexType>
    private var indexBuffer: MetalBuffer<VertexBuffer.IndexType>
    
    var demoScene: DemoScene!
    
    init(metalKitView: MTKView) {
        metalDevice = MTLCreateSystemDefaultDevice()
        metalCommandQueue = metalDevice.makeCommandQueue()
        metalKitView.device = metalDevice
        
        vertexBuffer = MetalBuffer(device: metalDevice, length: 1024)!
        indexBuffer = MetalBuffer(device: metalDevice, length: 1024)!
        
        super.init()
        
        setupMetal()
        metalKitView.sampleCount = multisampleLevel
        metalKitView.delegate = self
        if #available(OSX 10.15, *) {
            if multisampleLevel > 1 {
                metalKitView.multisampleColorAttachmentTextureUsage = .renderTarget
            }
        }
        demoScene = DemoScene(boundsSize: metalKitView.bounds.size, delegate: self)
        demoScene.initializeLevel()
    }
    
    private func setupMetal() {
        detectMultisampleLevel()
        
        let defaultLibrary = metalDevice.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineStateDescriptor.sampleCount = multisampleLevel
        
        pipelineState = try! metalDevice
            .makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    private func detectMultisampleLevel() {
        var level = 8
        while level > 1 {
            if metalDevice.supportsTextureSampleCount(level) {
                break
            }
            level /= 2
        }
        
        multisampleLevel = level
    }
    
    private func updateGameState() {
        /// Update any game state before rendering
        demoScene.update(timeSinceLastFrame: 1000.0 / 60.0)
    }
    
    func draw(in view: MTKView) {
        /// Per frame updates hare
        updateGameState()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        if multisampleLevel > 1 {
            renderPassDescriptor.colorAttachments[0].texture = view.multisampleColorTexture
            renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
            renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        } else {
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        }
        
        renderPassDescriptor.colorAttachments[0]
            .clearColor = MTLClearColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            return
        }
        guard let renderEncoder = commandBuffer
            .makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        demoScene.renderToVaoBuffer()
        renderVertices(demoScene.vertexBuffer, renderEncoder: renderEncoder)
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func renderVertices(_ buffer: VertexBuffer, renderEncoder: MTLRenderCommandEncoder) {
        if !vertexBuffer.setData(buffer.vertices, device: metalDevice) {
            print("Could not allocate vertex buffer @\(#file):\(#line - 1)")
            return
        }
        if !indexBuffer.setData(buffer.indices, device: metalDevice) {
            print("Could not allocate index buffer @\(#file):\(#line - 1)")
            return
        }
        
        renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: 0)
        renderEncoder
            .drawIndexedPrimitives(type: .triangle,
                                   indexCount: buffer.indices.count,
                                   indexType: .uint32,
                                   indexBuffer: indexBuffer.buffer,
                                   indexBufferOffset: 0)
    }
}

// MARK: - DemoSceneDelegate
extension Renderer: DemoSceneDelegate {
    func didUpdatePhysicsTimer(intervalCount: Int,
                               timeMilliRounded: TimeInterval,
                               fps: TimeInterval,
                               avgMilliRounded: TimeInterval) {
        
    }
    func didUpdateRenderTimer(timeMilliRounded: TimeInterval, fps: TimeInterval) {
        
    }
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
