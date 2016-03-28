//
//  PolyDrawer.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 09/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import SpriteKit

internal struct Poly
{
    let points: [CGPoint]
    let lineColor: SKColor
    let fillColor: SKColor
    
    var bounds: CGRect
    {
        return AABB(points: points.map(Vector2.init)).cgRect
    }
    
    init(points: [CGPoint], lineColor: SKColor, fillColor: SKColor)
    {
        self.points = points
        self.lineColor = lineColor
        self.fillColor = fillColor
    }
}

/// A polygon drawing helper that caches SKSpriteNodes and uses CGPaths to draw custom polygons.
/// Not the most elegant or fastest way, but SpriteKit lacks any viable options for constant drawing
/// of arbitrary polygons easily.
class SpriteKitPolyDrawer
{
    /// The scene that holds this PolyDrawer
    private var scene: SKScene
    
    /// An array of polygons to draw on the next flush call
    private var polys: [Poly] = []
    /// The canvas to draw the polygons onto
    private var canvas: SKSpriteNode
    
    /// Pool of nodes
    private var pool: ShapePool
    
    init(scene: SKScene)
    {
        self.scene = scene
        
        canvas = SKSpriteNode()
        canvas.anchorPoint = CGPointZero
        self.scene.addChild(canvas)
        
        pool = ShapePool(startSize: 5)
    }
    
    func queuePoly(vertices: [CGPoint], fillColor: UInt, strokeColor: UInt)
    {
        let poly = Poly(points: vertices, lineColor: skColorFromUInt(strokeColor), fillColor: skColorFromUInt(fillColor))
        
        polys += poly
    }
    
    /// Flushes all the polygons currently queued and draw them on the screen
    func renderPolys()
    {
        let area = CGRect(origin: CGPoint(), size: scene.size)
        
        canvas.removeAllChildren()
        
        if(polys.count == 0)
        {
            return
        }
        
        let path = CGPathCreateMutable()
        
        for pi in 0..<polys.count //poly in polys
        {
            let poly = polys[pi]
            
            // Verify polygon boundaries
            if(!poly.bounds.intersects(area))
            {
                continue
            }
            
            let c = poly.points.count == 2 ? poly.points.count : poly.points.count + 1
            
            let p = UnsafeMutablePointer<CGPoint>.alloc(c)
            
            for i in 0..<c
            {
                p[i] = poly.points[i % poly.points.count]
            }
            
            CGPathAddLines(path, nil, p, c)
            
            p.dealloc(c)
            
            //let node = pool.poolShape() //SKShapeNode(points: p, count: UInt(poly.points.count + 1))
            //node.path = path
        }
        
        let node = SKShapeNode()
        
        node.path = path
        node.fillColor = SKColor.whiteColor()
        node.strokeColor = SKColor.blackColor()
        node.lineJoin = .Round
        node.lineWidth = 2
        
        canvas.addChild(node)
    }
    
    /// Renders the contents of this PolyDrawer on a given CGContextRef
    func renderOnContext(context: CGContextRef)
    {
        for pi in 0..<polys.count //poly in polys
        {
            let poly = polys[pi]
            
            let p = UnsafeMutablePointer<CGPoint>.alloc(poly.points.count + 1)
            
            for i in 0..<poly.points.count + 1
            {
                p[i] = poly.points[i % poly.points.count]
            }
            
            let path = CGPathCreateMutable()
            let transform = UnsafeMutablePointer<CGAffineTransform>.alloc(1)
            transform[0] = CGAffineTransformIdentity
            
            CGPathAddLines(path, transform, p, poly.points.count + 1)
            
            p.dealloc(poly.points.count + 1)
            
            CGContextSetStrokeColorWithColor(context, poly.lineColor.CGColor)
            CGContextSetFillColorWithColor(context, poly.fillColor.CGColor)
            
            CGContextAddPath(context, path)
            CGContextDrawPath(context, .FillStroke)
        }
    }
    
    /// Resets this PolyDrawer
    func reset()
    {
        polys = []
    }
}

/// Pools SKShapes for reusage
private class ShapePool
{
    /// The pool of nodes
    private var shapePool:[SKShapeNode]
    
    /// Initializes a new ShapePool, with a specified starting size for the pool
    init(startSize: Int)
    {
        // Init the starting pool
        shapePool = []
        
        for _ in 0..<startSize
        {
            shapePool += SKShapeNode()
        }
    }
    
    /// Pools a new shape from the node pool
    func poolShape() -> SKShapeNode
    {
        // Try to fetch a node from the pool, returning a new one if the pooling fails
        if(shapePool.count == 0)
        {
            return SKShapeNode()
        }
        
        return shapePool.removeLast()
    }
    
    /// Repools a node back into this shape pool
    func repoolShape(shape : SKShapeNode)
    {
        shapePool += shape
    }
}

func skColorFromUInt(color: UInt) -> SKColor
{
    let a = CGFloat((UInt(color >> 24) & UInt(0xFF))) / 255.0
    let r = CGFloat((UInt(color >> 16) & UInt(0xFF))) / 255.0
    let g = CGFloat((UInt(color >> 8) & UInt(0xFF))) / 255.0
    let b = CGFloat((color & UInt(0xFF))) / 255.0
    
    return SKColor(red: r, green: g, blue: b, alpha: a)
}