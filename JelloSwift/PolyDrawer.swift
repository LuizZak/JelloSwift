//
//  PolyDrawer.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 09/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import SpriteKit

private struct Poly
{
    let points: [CGPoint];
    let lineColor: SKColor;
    let fillColor: SKColor;
    
    var bounds: CGRect
    {
        return AABB(points: points.map{ Vector2($0) }).cgRect;
    }
    
    init(points: [CGPoint], lineColor: SKColor, fillColor: SKColor)
    {
        self.points = points;
        self.lineColor = lineColor;
        self.fillColor = fillColor;
    }
}

/// A polygon drawing helper that caches SKSpriteNodes and uses CGPaths to draw custom polygons.
/// Not the most elegant or fastest way, but SpriteKit lacks any viable options for constant drawing
/// of arbitrary polygons easily.
class PolyDrawer
{
    /// The scene that holds this PolyDrawer
    private var scene: SKScene?;
    
    /// An array of polygons to draw on the next flush call
    private var polys: [Poly] = [];
    /// The canvas to draw the polygons onto
    private var canvas: SKSpriteNode;
    
    /// Pool of nodes
    private var pool: ShapePool;
    
    init(scene: SKScene)
    {
        self.scene = scene;
        
        self.canvas = SKSpriteNode();
        self.canvas.anchorPoint = CGPointZero;
        self.scene?.addChild(canvas);
        
        self.pool = ShapePool(startSize: 5);
    }
    
    init(view: UIView)
    {
        self.canvas = SKSpriteNode();
        self.pool = ShapePool(startSize: 5);
    }
    
    func queuePoly(vertices: [CGPoint], fillColor: UInt, strokeColor: UInt)
    {
        var converted: [CGPoint] = [];
        var poly:Poly = Poly(points: vertices, lineColor: skColorFromUInt(strokeColor), fillColor: skColorFromUInt(fillColor));
        
        self.polys += poly;
    }
    
    /// Flushes all the polygons currently queued and draw them on the screen
    func renderPolys()
    {
        var area = CGRect(origin: CGPoint(), size: self.scene!.size);
        
        canvas.removeAllChildren();
        
        if(polys.count == 0)
        {
            return;
        }
        
        let path = CGPathCreateMutable();
        let transform = UnsafeMutablePointer<CGAffineTransform>.alloc(1);
        transform[0] = CGAffineTransformIdentity;
        
        for pi in 0..<polys.count //poly in polys
        {
            let poly = polys[pi];
            
            // Verify polygon boundaries
            if(!poly.bounds.intersects(area))
            {
                continue;
            }
            
            let c = poly.points.count == 2 ? poly.points.count : poly.points.count + 1;
            
            let p = UnsafeMutablePointer<CGPoint>.alloc(c);
            
            for i in 0..<c
            {
                p[i] = poly.points[i % poly.points.count];
            }
            
            CGPathAddLines(path, transform, p, UInt(c))
            
            p.dealloc(c);
            
            //let node = pool.poolShape(); //SKShapeNode(points: p, count: UInt(poly.points.count + 1));
            //node.path = path;
        }
        
        let node = SKShapeNode();
        
        node.path = path;
        node.fillColor = SKColor.whiteColor();
        node.strokeColor = SKColor.blackColor();
        node.lineJoin = kCGLineJoinRound;
        node.lineWidth = 2;
        
        canvas.addChild(node);
        
        
        // Repool all shapes
        /*
        for shape in canvas.children
        {
            if let s = shape as? SKShapeNode
            {
                //pool.repoolShape(s);
            }
        }
        */
        
        /*
        canvas.removeAllChildren();
        
        for pi in 0..<polys.count //poly in polys
        {
            let poly = polys[pi];
            
            let p = UnsafeMutablePointer<CGPoint>.alloc(poly.points.count + 1);
            
            for i in 0..<poly.points.count + 1
            {
                p[i] = poly.points[i % poly.points.count];
            }
            
            //let path = CGPathCreateMutable();
            //let transform = UnsafeMutablePointer<CGAffineTransform>.alloc(1);
            //transform[0] = CGAffineTransformIdentity;
            
            //CGPathAddLines(path, transform, p, UInt(poly.points.count + 1))
            
            //p.dealloc(poly.points.count + 1);
            
            //let node = pool.poolShape(); //SKShapeNode(points: p, count: UInt(poly.points.count + 1));
            //node.path = path;
            
            let node = SKShapeNode(points: p, count: UInt(poly.points.count + 1));
            
            node.fillColor = poly.fillColor;
            node.strokeColor = poly.lineColor;
            node.lineWidth = 1;
            
            canvas.addChild(node);
        }
        // */
    }
    
    /// Renders the contents of this PolyDrawer on a given CGContextRef
    func renderOnContext(context: CGContextRef)
    {
        for pi in 0..<polys.count //poly in polys
        {
            let poly = polys[pi];
            
            let p = UnsafeMutablePointer<CGPoint>.alloc(poly.points.count + 1);
            
            for i in 0..<poly.points.count + 1
            {
                p[i] = poly.points[i % poly.points.count];
            }
            
            let path = CGPathCreateMutable();
            let transform = UnsafeMutablePointer<CGAffineTransform>.alloc(1);
            transform[0] = CGAffineTransformIdentity;
            
            CGPathAddLines(path, transform, p, UInt(poly.points.count + 1))
            
            p.dealloc(poly.points.count + 1);
            
            CGContextSetStrokeColorWithColor(context, poly.lineColor.CGColor);
            CGContextSetFillColorWithColor(context, poly.fillColor.CGColor);
            
            CGContextAddPath(context, path);
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
    
    /// Resets this PolyDrawer
    func reset()
    {
        polys = [];
    }
}

/// Pools SKShapes for reusage
private class ShapePool
{
    /// The pool of nodes
    private var shapePool:[SKShapeNode];
    
    /// Initializes a new ShapePool, with a specified starting size for the pool
    init(startSize: Int)
    {
        // Init the starting pool
        self.shapePool = [];
        
        for i in 0..<startSize
        {
            self.shapePool += SKShapeNode();
        }
    }
    
    /// Pools a new shape from the node pool
    func poolShape() -> SKShapeNode
    {
        // Try to fetch a node from the pool, returning a new one if the pooling fails
        if(shapePool.count == 0)
        {
            return SKShapeNode();
        }
        
        return shapePool.removeLast();
    }
    
    /// Repools a node back into this shape pool
    func repoolShape(shape : SKShapeNode)
    {
        shapePool += shape;
    }
}

func skColorFromUInt(color: UInt) -> SKColor
{
    var a: CGFloat = CGFloat((UInt(color >> 24) & UInt(0xFF))) / 255.0;
    var r: CGFloat = CGFloat((UInt(color >> 16) & UInt(0xFF))) / 255.0;
    var g: CGFloat = CGFloat((UInt(color >> 8) & UInt(0xFF))) / 255.0;
    var b: CGFloat = CGFloat((color & UInt(0xFF))) / 255.0;
    
    return SKColor(red: r, green: g, blue: b, alpha: a);
}