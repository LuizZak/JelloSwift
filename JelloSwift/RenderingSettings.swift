//
//  RenderingSettings.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 08/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// The point size of points drawn on screen (this value is independent of the Scale vector)
var pointSize: CGFloat = 3;

// Why is the Y vector negative? The engine is a port of an XNA engine (JelloPhysics).
// XNA is basicly 3D, so the Y vector grows up instead of down, like in a 2D screen (Say, Flash)
var renderingScale = Vector2(25.8, 25.8);

// The offset is independent of the scale, unlike Flash DisplayObject's x-y coordinates and scaleX-scaleY
var renderingOffset = Vector2(300, -50);

// Transforms the given point on stage coordinates into World coordinates by using the rendering settings
func toWorldCoords(point: Vector2) -> Vector2
{
    return Vector2((point.X - renderingOffset.X) / renderingScale.X, (point.Y - renderingOffset.Y) / renderingScale.Y);
}

// Transforms the given point on World coordinates into Screen coordinates by using the rendering settings
func toScreenCoords(point: Vector2) -> Vector2
{
    return Vector2(point.X * renderingScale.X + renderingOffset.X, point.Y * renderingScale.Y + renderingOffset.Y);
}

// Sets the camera position and scale from scalar values
func setCamera(positionX: CGFloat, positionY: CGFloat, scaleX: CGFloat, scaleY: CGFloat)
{
    renderingOffset.X = positionX;
    renderingOffset.Y = positionY;
    
    renderingScale.X = scaleX;
    renderingScale.Y = scaleY;
}