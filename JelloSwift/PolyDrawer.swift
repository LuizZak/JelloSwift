//
//  PolyDrawer.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 09/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

private struct Poly
{
    let points: [CGPoint];
    let fillColor: UIColor;
    let lineColor: UIColor;
    let lineWidth: CGFloat;
    
    let fillColorUInt: UInt;
    let lineColorUInt: UInt;
    
    var bounds: CGRect
    {
        return AABB(points: points.map{ Vector2($0) }).cgRect;
    }
    
    init(points: [CGPoint], lineColor: UInt, fillColor: UInt, lineWidth: CGFloat)
    {
        // Wrap the values around so the shape is closed
        var p = points;
        if let first = p.first
        {
            p.append(first);
        }
        
        self.points = p;
        self.lineColor = uiColorFromUInt(lineColor);
        self.fillColor = uiColorFromUInt(fillColor);
        self.lineColorUInt = lineColor;
        self.fillColorUInt = fillColor;
        self.lineWidth = lineWidth;
    }
}

/// A polygon drawing helper that caches SKSpriteNodes and uses CGPaths to draw custom polygons.
/// Not the most elegant or fastest way, but SpriteKit lacks any viable options for constant drawing
/// of arbitrary polygons easily.
class PolyDrawer
{
    /// An array of polygons to draw on the next flush call
    private var polys: [Poly] = [];
    
    func queuePoly(vertices: [CGPoint], fillColor: UInt, strokeColor: UInt, lineWidth: CGFloat = 3)
    {
        var converted: [CGPoint] = [];
        var poly:Poly = Poly(points: vertices, lineColor: strokeColor, fillColor: fillColor, lineWidth: lineWidth);
        
        self.polys += poly;
    }
    
    /// Renders the contents of this PolyDrawer on a given CGContextRef
    func renderOnContext(context: CGContextRef)
    {
        for poly in polys
        {
            CGContextSaveGState(context);
            
            let path = CGPathCreateMutable();
            
            var f = CGAffineTransformIdentity;
            CGPathAddLines(path, &f, poly.points, UInt(poly.points.count))
            
            CGContextSetStrokeColorWithColor(context, poly.lineColor.CGColor);
            CGContextSetFillColorWithColor(context, poly.fillColor.CGColor);
            CGContextSetLineWidth(context, poly.lineWidth);
            CGContextSetLineJoin(context, kCGLineJoinRound);
            CGContextSetLineCap(context, kCGLineCapRound);
            
            let hasFill = ((poly.fillColorUInt >> 24) & 0xFF) != 0;
            let hasLine = ((poly.lineColorUInt >> 24) & 0xFF) != 0;
            
            if(hasLine && hasFill && poly.points.count > 3)
            {
                CGContextAddPath(context, path);
                CGContextDrawPath(context, kCGPathFillStroke);
            }
            else
            {
                if(hasFill && poly.points.count > 3)
                {
                    CGContextAddPath(context, path);
                    CGContextFillPath(context);
                }
                if(hasLine)
                {
                    CGContextAddPath(context, path);
                    CGContextStrokePath(context);
                }
            }
            
            CGContextRestoreGState(context);
        }
    }
    
    /// Resets this PolyDrawer
    func reset()
    {
        polys = [];
    }
}

func uiColorFromUInt(color: UInt) -> UIColor
{
    var a: CGFloat = CGFloat((UInt(color >> 24) & UInt(0xFF))) / 255.0;
    var r: CGFloat = CGFloat((UInt(color >> 16) & UInt(0xFF))) / 255.0;
    var g: CGFloat = CGFloat((UInt(color >> 8) & UInt(0xFF))) / 255.0;
    var b: CGFloat = CGFloat((color & UInt(0xFF))) / 255.0;
    
    return UIColor(red: r, green: g, blue: b, alpha: a);
}