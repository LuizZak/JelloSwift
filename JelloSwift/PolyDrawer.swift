//
//  PolyDrawer.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 09/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

private struct CoreGraphicsPoly
{
    let points: [CGPoint]
    let fillColor: UIColor
    let lineColor: UIColor
    let lineWidth: CGFloat
    
    let fillColorUInt: UInt
    let lineColorUInt: UInt
    
    var bounds: CGRect
    {
        return AABB(points: points.map { Vector2($0) }).cgRect
    }
    
    init(var points: [CGPoint], lineColor: UInt, fillColor: UInt, lineWidth: CGFloat)
    {
        // Wrap the values around so the shape is closed
        if let first = points.first
        {
            points.append(first)
        }
        
        self.points = points
        self.lineColor = colorFromUInt(lineColor)
        self.fillColor = colorFromUInt(fillColor)
        lineColorUInt = lineColor
        fillColorUInt = fillColor
        self.lineWidth = lineWidth
    }
}

/// A polygon drawing helper that caches SKSpriteNodes and uses CGPaths to draw custom polygons.
/// Not the most elegant or fastest way, but SpriteKit lacks any viable options for constant drawing
/// of arbitrary polygons easily.
class PolyDrawer
{
    /// An array of polygons to draw on the next flush call
    private var polys: [CoreGraphicsPoly] = []
    
    func queuePoly<T: SequenceType where T.Generator.Element == CGPoint>(vertices: T, fillColor: UInt, strokeColor: UInt, lineWidth: CGFloat = 3)
    {
        let poly = CoreGraphicsPoly(points: [CGPoint](vertices), lineColor: strokeColor, fillColor: fillColor, lineWidth: lineWidth)
        
        self.polys += poly
    }
    
    /// Renders the contents of this PolyDrawer on a given CGContextRef
    func renderOnContext(context: CGContextRef)
    {
        for poly in polys
        {
            let hasFill = ((poly.fillColorUInt >> 24) & 0xFF) != 0
            let hasLine = ((poly.lineColorUInt >> 24) & 0xFF) != 0
            
            // Shape is invisible
            if(!hasFill && !hasLine)
            {
                continue
            }
            
            CGContextSaveGState(context)
            
            let path = CGPathCreateMutable()
            
            CGPathAddLines(path, nil, poly.points, poly.points.count)
          
            CGContextSetStrokeColorWithColor(context, poly.lineColor.CGColor)
            CGContextSetFillColorWithColor(context, poly.fillColor.CGColor)
            CGContextSetLineWidth(context, poly.lineWidth)
            CGContextSetLineJoin(context, CGLineJoin.Round)
            CGContextSetLineCap(context, CGLineCap.Round)
            
            CGContextAddPath(context, path)
            
            if(hasLine && hasFill && poly.points.count > 3)
            {
                CGContextDrawPath(context, CGPathDrawingMode.FillStroke)
            }
            else
            {
                if(hasFill && poly.points.count > 3)
                {
                    CGContextFillPath(context)
                }
                if(hasLine)
                {
                    CGContextStrokePath(context)
                }
            }
            
            CGContextRestoreGState(context)
        }
    }
    
    /// Resets this PolyDrawer
    func reset()
    {
        polys.removeAll(keepCapacity: false)
    }
}

func colorFromUInt(color: UInt) -> UIColor
{
    let a = CGFloat((color >> 24) & 0xFF) / 255.0
    let r = CGFloat((color >> 16) & 0xFF) / 255.0
    let g = CGFloat((color >> 8) & 0xFF) / 255.0
    let b = CGFloat(color & 0xFF) / 255.0
    
    return UIColor(red: r, green: g, blue: b, alpha: a)
}