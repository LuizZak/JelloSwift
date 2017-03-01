//
//  Shader.swift
//  Squishy2048
//
//  Created by Luiz Fernando Silva on 26/02/17.
//  Copyright © 2017 Luiz Fernando Silva. All rights reserved.
//

import UIKit

func compileShader(_ shaderName: String, shaderType: GLenum) -> GLuint {
    
    // Get NSString with contents of our shader file.
    let shaderPath = Bundle.main.path(forResource: shaderName, ofType: "glsl")
    let shaderString = try! String(contentsOfFile: shaderPath!)
    
    // Tell OpenGL to create an OpenGL object to represent the shader, indicating if it's a vertex or a fragment shader.
    let shaderHandle = glCreateShader(shaderType)
    
    if shaderHandle == 0 {
        NSLog("Couldn't create shader")
    }
    
    // Conver shader string to CString and call glShaderSource to give OpenGL the source for the shader.
    let cString = shaderString.utf8CString
    shaderString.withCString { (pointer: UnsafePointer<Int8>) -> Void in
        pointer.withMemoryRebound(to: GLchar.self, capacity: cString.count) { (p: UnsafePointer<GLchar>) -> Void in
            var p: UnsafePointer<GLchar>? = p
            var shaderStringLength: GLint = GLint(Int32(shaderString.utf8CString.count))
            glShaderSource(shaderHandle, 1, &p, &shaderStringLength)
            
            // Tell OpenGL to compile the shader.
            glCompileShader(shaderHandle)
            
            // But compiling can fail! If we have errors in our GLSL code, we can here and output any errors.
            var compileSuccess: GLint = GLint()
            glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileSuccess)
            if (compileSuccess == GL_FALSE) {
                print("Failed to compile shader!")
                // TODO: Actually output the error that we can get from the glGetShaderInfoLog function.
                exit(1)
            }
        }
    }
    
    return shaderHandle
}
