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
    var points: [CGPoint];
    var lineColor: SKColor;
    var fillColor: SKColor;
    
    
    init(points: [CGPoint], lineColor: SKColor, fillColor: SKColor)
    {
        self.points = points;
        self.lineColor = lineColor;
        self.fillColor = fillColor;
    }
}

// A polygon drawing helper that caches SKSpriteNodes and uses CGPaths to draw custom polygons.
// Not the most elegant or fastest way, but SpriteKit lacks any viable options for constant drawing
// of arbitrary polygons easily.
class PolyDrawer: NSObject
{
    // The scene that holds this PolyDrawer
    private var scene: SKScene;
    
    // An array of polygons to draw on the next flush call
    private var polys: [Poly] = [];
    // The canvas to draw the polygons onto
    private var canvas: SKSpriteNode;
    
    init(scene: SKScene)
    {
        self.scene = scene;
        
        self.canvas = SKSpriteNode();
        self.canvas.anchorPoint = CGPointZero;
        self.scene.addChild(canvas);
        
        super.init();
    }
    
    func drawPoly(vertices: [CGPoint], fillColor: UInt, strokeColor: UInt)
    {
        var converted: [CGPoint] = [];
        var poly:Poly = Poly(points: vertices, lineColor: skColorFromUInt(strokeColor), fillColor: skColorFromUInt(fillColor));
        
        self.polys += poly;
    }
    
    // Flushes all the polygons currently queued and draw them on the screen
    func flushPolys()
    {
        let size = CGSize(width: scene.size.width, height: scene.size.height);
        
        UIGraphicsBeginImageContext(size);
        let ctx = UIGraphicsGetCurrentContext();
        
        for poly in polys
        {
            // Set stroke and fill
            poly.lineColor.setStroke();
            poly.fillColor.setFill();
            
            CGContextBeginPath(ctx);
            
            // Draw the polygon
            CGContextMoveToPoint(ctx, poly.points[0].x, size.height - poly.points[0].y);
            for i in 1..<poly.points.count+1
            {
                let v = poly.points[i % poly.points.count];
                CGContextAddLineToPoint(ctx, v.x, size.height - v.y);
            }
            CGContextDrawPath(ctx, kCGPathFillStroke);
        }
        
        var textureImage = UIGraphicsGetImageFromCurrentImageContext();
        
        var texture = SKTexture(image: textureImage);
        
        self.canvas.texture = texture;
        self.canvas.size = texture.size();
        
        UIGraphicsEndImageContext();
    }
    
    // Resets this PolyDrawer
    func reset()
    {
        polys = [];
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