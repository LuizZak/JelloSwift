//
//  RenderingSettings.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 08/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// The rendering scale for the scene
public var renderingScale = Vector2(x: 25.8, y: 25.8)

/// The offset is independent of the scale, unlike Flash DisplayObject's x-y
/// coordinates and scaleX-scaleY
public var renderingOffset = Vector2(x: 300, y: -50)

/// Transforms the given point on stage coordinates into World coordinates by
/// using the rendering settings
public func toWorldCoords(_ point: Vector2) -> Vector2 {
    return (point - renderingOffset) / renderingScale
}

/// Transforms the given point on World coordinates into Screen coordinates by
/// using the rendering settings
public func toScreenCoords(_ point: Vector2) -> Vector2 {
    return point * renderingScale + renderingOffset
}

/// Transforms a given AABB from world coordinates to screen coordinates
public func toScreenSpace(_ aabb: AABB) -> AABB {
    return AABB(
        min: toScreenCoords(aabb.minimum),
        max: toScreenCoords(aabb.maximum)
    )
}

/// Transforms a given AABB from screen coordinates to world coordinates
public func toWorldSpace(_ aabb: AABB) -> AABB {
    return AABB(
        min: toWorldCoords(aabb.minimum),
        max: toWorldCoords(aabb.maximum)
    )
}

public func setCamera(_ position: Vector2, scale: Vector2) {
    renderingOffset = position
    renderingScale = scale
}

/// Sets the camera position and scale from scalar values
public func setCamera(
    positionX: JFloat,
    positionY: JFloat,
    scaleX: JFloat,
    scaleY: JFloat
) {
    renderingOffset.x = positionX
    renderingOffset.y = positionY

    renderingScale.x = scaleX
    renderingScale.y = scaleY
}
