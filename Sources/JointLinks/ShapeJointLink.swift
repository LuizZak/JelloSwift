//
//  BaseBodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation

/// Represents a joint link that links to multiple point masses of a body
open class ShapeJointLink: JointLink {
    /// The indices of this shape joint link
    fileprivate let _indexes: [Int]

    /// Gets the body that this joint link is linked to
    open fileprivate(set) unowned var body: Body

    /// Gets the type of joint this joint link represents
    public let linkType = LinkType.shape

    /// The offset to apply to the position of this shape joint, in body
    /// coordinates
    open var offset = Vector2.zero

    /// Gets the position, in world coordinates, at which this joint links with
    /// the underlying body
    open var position: Vector2 {
        var average = Vector2.zero

        for i in _indexes {
            average += body.pointMasses[i].position
        }

        return average / JFloat(_indexes.count) + offsetPosition
    }

    /// Offset position, calculated based on the owning body's angle
    fileprivate var offsetPosition: Vector2 {
        if offset == Vector2.zero {
            return Vector2.zero
        }

        return offset.rotated(by: angle())
    }

    /// Gets the velocity of the object this joint links to
    open var velocity: Vector2 {
        var average = Vector2.zero

        for i in _indexes {
            average += body.pointMasses[i].velocity
        }

        return average / JFloat(_indexes.count)
    }

    /// Gets the total mass of the subject of this joint link
    open var mass: JFloat {
        var sum: JFloat = 0

        for i in _indexes {
            sum += body.pointMasses[i].mass
        }

        return sum
    }

    /// Gets a value specifying whether the object referenced by this
    /// JointLinkType is static
    open var isStatic: Bool {
        for i in _indexes {
            if body.pointMasses[i].mass.isInfinite {
                return true
            }
        }

        return false
    }

    /// Inits a new point joint link with the specified parameters
    public init(body: Body, pointMassIndexes: [Int]) {
        self.body = body
        _indexes = pointMassIndexes
    }

    /// Applies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    open func applyForce(of force: Vector2) {
        let torqueF = offsetPosition • force.perpendicular()

        for i in _indexes {
            let p = body.pointMasses[i]
            let tempR = (p.position - position + offsetPosition).perpendicular()

            body.applyForce(force + tempR * torqueF, toPointMassAt: i)
        }
    }

    /// Applies a direct positional translation of this joint link by a given
    /// offset.
    ///
    /// - parameter offset: An offset to apply to the member(s) of this joint link.
    open func translate(by offset: Vector2) {
        for i in _indexes {
            let position = body.pointMasses[i].position
            body.setPosition(position + offset, ofPointMassAt: i)
        }
    }

    // TODO: Implement the function below to derive the shape's angle

    /// Returns the average angle of the vertices of this ShapeJointLink, based
    /// on the body's original shape's vertices
    fileprivate func angle() -> JFloat {
        var angle: JFloat = 0

        var originalSign = 1
        var originalAngle: JFloat = 0

        var first = true
        for i in _indexes {
            let pm = body.pointMasses[i]
            let base = body.baseShape[i]

            let baseNorm = base.normalized()
            let curNorm  = (pm.position - body.derivedPos).normalized()

            var thisAngle = atan2(baseNorm.x * curNorm.y - baseNorm.y * curNorm.x, baseNorm • curNorm)

            if first {
                originalSign = (thisAngle >= 0.0) ? 1 : -1
                originalAngle = thisAngle

                first = false
            } else {
                let diff = (thisAngle - originalAngle)
                let thisSign = (thisAngle >= 0.0) ? 1 : -1

                if abs(diff) > .pi && (thisSign != originalSign) {
                    if thisSign == -1 {
                        thisAngle = .pi + (.pi + thisAngle)
                    } else {
                        thisAngle = (.pi - thisAngle) - .pi
                    }
                }
            }

            angle += thisAngle
        }

        angle /= JFloat(_indexes.count)

        return angle
    }
}
