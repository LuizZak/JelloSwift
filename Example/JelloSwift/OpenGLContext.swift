//
//  OpenGLContext.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 26/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import OpenGLES
import GLKit

/// An OpenGL context instance for representing created OpenGL contexts with
class OpenGLContext {
    
    var context: EAGLContext!
    var layer: CAEAGLLayer
    
    var positionSlot: GLuint = 0
    var colorSlot: GLuint = 0
    
    var frameBuffer: GLuint = 0
    var colorRenderBuffer: GLuint = 0
    
    var sampleFramebuffer: GLuint = 0
    var sampleColorRenderBuffer: GLuint = 0
    var sampleDepthRenderbuffer: GLuint = 0
    
    var shaderProgram: GLuint = 0
    
    /// A Mat4 slot for applying vertex transformations to the underlying shader
    var transformMatrixSlot: GLuint = 0
    
    init(layer: CAEAGLLayer) {
        self.layer = layer
        
        // Just like with CoreGraphics, in order to do much with OpenGL, we need a context.
        // Here we create a new context with the version of the rendering API we want and
        // tells OpenGL that when we draw, we want to do so within this context.
        setupContext()
        
        resetContext()
        compileShaders()
    }
    
    func resetContext() {
        setupRenderBuffer()
        setupFrameBuffer()
        setupMultisamplingBuffer()
        
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderBuffer)
    }
    
    func setupContext() {
        guard let context = EAGLContext(api: .openGLES2) else {
            print("Failed to initialize OpenGLES 2.0 context!")
            exit(1)
        }
        
        if (!EAGLContext.setCurrent(context)) {
            print("Failed to set current OpenGL context!")
            exit(1)
        }
        
        self.context = context
        
        // Turn on transparency
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glEnable(GLenum(GL_BLEND))
    }
    
    func setupRenderBuffer() {
        // Destroy previous render buffers
        if(colorRenderBuffer != 0) {
            glDeleteRenderbuffers(1, &colorRenderBuffer)
            colorRenderBuffer = 0
        }
        
        glGenRenderbuffers(1, &colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderBuffer)
        
        context.renderbufferStorage(Int(GL_RENDERBUFFER), from: layer)
    }
    
    func setupFrameBuffer() {
        // Destroy any previous frame buffer
        if(frameBuffer != 0) {
            glDeleteFramebuffers(1, &frameBuffer)
            frameBuffer = 0
        }
        
        glGenFramebuffers(1, &frameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), colorRenderBuffer)
    }
    
    func setupMultisamplingBuffer() {
        if(sampleFramebuffer != 0) {
            glDeleteFramebuffers(1, &sampleFramebuffer)
            sampleFramebuffer = 0
        }
        if(sampleColorRenderBuffer != 0) {
            glDeleteRenderbuffers(1, &sampleColorRenderBuffer)
            sampleColorRenderBuffer = 0
        }
        if(sampleDepthRenderbuffer != 0) {
            glDeleteRenderbuffers(1, &sampleDepthRenderbuffer)
            sampleDepthRenderbuffer = 0
        }
        
        let width = GLint(layer.frame.width)
        let height = GLint(layer.frame.height)
        
        glGenFramebuffers(1, &sampleFramebuffer);
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), sampleFramebuffer);
        
        glGenRenderbuffers(1, &sampleColorRenderBuffer);
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), sampleColorRenderBuffer);
        glRenderbufferStorageMultisampleAPPLE(GLenum(GL_RENDERBUFFER), 4, GLenum(GL_RGBA8_OES), width, height);
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), sampleColorRenderBuffer);
        
        glGenRenderbuffers(1, &sampleDepthRenderbuffer);
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), sampleDepthRenderbuffer);
        
        glRenderbufferStorageMultisampleAPPLE(GLenum(GL_RENDERBUFFER), 4, GLenum(GL_DEPTH_COMPONENT16), width, height);
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), sampleDepthRenderbuffer);
        
        if (glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) != GLuint(GL_FRAMEBUFFER_COMPLETE)) {
            NSLog("Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)));
        }
    }
    
    func compileShaders() {
        
        if(shaderProgram != 0) {
            glDeleteProgram(shaderProgram)
            shaderProgram = 0
        }
        
        // Compile our vertex and fragment shaders.
        let vertexShader: GLuint = compileShader("SimpleVertex", shaderType: GLenum(GL_VERTEX_SHADER))
        let fragmentShader: GLuint = compileShader("SimpleFragment", shaderType: GLenum(GL_FRAGMENT_SHADER))
        
        // Call glCreateProgram, glAttachShader, and glLinkProgram to link the vertex and fragment shaders into a complete program.
        shaderProgram = glCreateProgram()
        glAttachShader(shaderProgram, vertexShader)
        glAttachShader(shaderProgram, fragmentShader)
        glLinkProgram(shaderProgram)
        
        // Check for any errors.
        var linkSuccess: GLint = GLint()
        glGetProgramiv(shaderProgram, GLenum(GL_LINK_STATUS), &linkSuccess)
        if (linkSuccess == GL_FALSE) {
            print("Failed to create shader program!")
            // TODO: Actually output the error that we can get from the glGetProgramInfoLog function.
            exit(1);
        }
        
        // Call glUseProgram to tell OpenGL to actually use this program when given vertex info.
        glUseProgram(shaderProgram)
        
        // Finally, call glGetAttribLocation to get a pointer to the input values for the vertex shader, so we
        // can set them in code. Also call glEnableVertexAttribArray to enable use of these arrays (they are disabled by default).
        positionSlot = GLuint(glGetAttribLocation(shaderProgram, "Position"))
        colorSlot = GLuint(glGetAttribLocation(shaderProgram, "SourceColor"))
        
        transformMatrixSlot = GLuint(glGetUniformLocation(shaderProgram, "mvp"))
        
        glEnableVertexAttribArray(positionSlot)
        glEnableVertexAttribArray(colorSlot)
    }
    
    /// Generates a new vertex array object with the default properties
    func generateVAO() -> VertexArrayObject {
        var vertex = VertexArrayObject(vao: 0, buffer: VertexBuffer())
        
        createVAO(for: &vertex)
        
        return vertex
    }
    
    /// Destroys a given vertex array object, and all related buffers
    func destroyVAO(_ vao: inout VertexArrayObject) {
        // Destroy previous references
        if(vao.vao != 0) {
            glDeleteVertexArraysOES(1, &vao.vao)
            vao.vao = 0
        }
        if(vao.buffer.vertexBuffer != 0) {
            glDeleteBuffers(1, &vao.buffer.vertexBuffer)
            vao.buffer.vertexBuffer = 0
        }
        if(vao.buffer.indexBuffer != 0) {
            glDeleteBuffers(1, &vao.buffer.indexBuffer)
            vao.buffer.indexBuffer = 0
        }
    }
    
    /// Creates a new VAO on the underlying.
    /// This method also deletes any previous assigned VAO (if vao.vao != 0)
    func createVAO(for vao: inout VertexArrayObject) {
        destroyVAO(&vao)
        
        // Re-generate
        glGenVertexArraysOES(1, &vao.vao)
        glBindVertexArrayOES(vao.vao)
        
        /// This pointer points to the color offset of the vertices buffer.
        let ptr = UnsafePointer<GLfloat>(bitPattern: Vertex.colorOffset)
        
        glGenBuffers(1, &vao.buffer.vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vao.buffer.vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vao.buffer.vertexBufferSize, vao.buffer.vertices, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(positionSlot)
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), nil)
        
        glEnableVertexAttribArray(colorSlot)
        glVertexAttribPointer(colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), ptr)
        
        glGenBuffers(1, &vao.buffer.indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), vao.buffer.indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), vao.buffer.indexBufferSize, vao.buffer.indices, GLenum(GL_STATIC_DRAW))
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindVertexArrayOES(0)
    }
    
    /// Updates the VAO for a given vertex array object instance
    func updateVAO(for vao: VertexArrayObject) {
        
        glBindVertexArrayOES(vao.vao)
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vao.buffer.vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vao.buffer.vertexBufferSize, vao.buffer.vertices, GLenum(GL_STATIC_DRAW))
        
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), vao.buffer.indexBufferSize, vao.buffer.indices, GLenum(GL_STATIC_DRAW))
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
        glBindVertexArrayOES(0)
    }
}
