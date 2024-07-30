//
//  BaseBodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

#if os(macOS) || os(iOS)
    import Darwin.C
#elseif os(Linux)
    import Glibc
#endif

/// Represents a joint link that links to multiple point masses of a body
open class WeightedShapeJointLink: JointLink {
    /// The entries of this shape joint link
    fileprivate let _entries: [PointMassEntry]

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
        var total: JFloat = .zero

        for entry in _entries {
            average += body.pointMasses[entry.index].position * entry.weight
            total += entry.weight
        }

        return average / total + offsetPosition
    }

    /// Offset position, calculated based on the owning body's angle
    fileprivate var offsetPosition: Vector2 {
        if offset == Vector2.zero {
            return Vector2.zero
        }

        return offset.rotated(by: body.derivedAngle)
    }

    /// Gets the velocity of the object this joint links to
    open var velocity: Vector2 {
        var average = Vector2.zero
        var total: JFloat = .zero

        for entry in _entries {
            average += body.pointMasses[entry.index].velocity * entry.weight
            total += entry.weight
        }

        return average / total
    }

    /// Gets the total mass of the subject of this joint link
    open var mass: JFloat {
        var sum: JFloat = 0

        for entry in _entries {
            sum += body.pointMasses[entry.index].mass
        }

        return sum
    }

    /// Gets a value specifying whether the object referenced by this
    /// JointLinkType is static
    open var isStatic: Bool {
        for entry in _entries {
            if body.pointMasses[entry.index].mass.isInfinite {
                return true
            }
        }

        return false
    }

    /// Inits a new point joint link with the specified parameters
    public init(
        body: Body,
        entries: [PointMassEntry]
    ) {
        self.body = body
        _entries = entries
    }

    /// Applies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    open func applyForce(of force: Vector2) {
        let torqueF = offsetPosition • force.perpendicular()

        for entry in _entries {
            let p = body.pointMasses[entry.index]
            let tempR = (p.position - position + offsetPosition).perpendicular()

            body.applyForce(force + tempR * torqueF, toPointMassAt: entry.index)
        }
    }

    // TODO: Implement the function below to derive the shape's angle

    /// Returns the average angle of the vertices of this ShapeJointLink, based
    /// on the body's original shape's vertices
    fileprivate func angle() -> JFloat {
        var angle: JFloat = 0

        var originalSign = 1
        var originalAngle: JFloat = 0
        var hasSeenValues = false

        for entry in _entries {
            defer { hasSeenValues = true }

            let pm = body.pointMasses[entry.index]

            let baseNorm = body.baseShape[entry.index].normalized()
            let curNorm  = (pm.position - body.derivedPos).normalized()

            var thisAngle = atan2(baseNorm.x * curNorm.y - baseNorm.y * curNorm.x, baseNorm • curNorm)

            if !hasSeenValues {
                originalSign = (thisAngle >= 0.0) ? 1 : -1
                originalAngle = thisAngle
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

        angle /= JFloat(_entries.count)

        return angle
    }

    /// An entry for a weighted shape joint link.
    public struct PointMassEntry {
        /// The index of the point mass on its original body.
        public var index: Int

        /// A weighted value applied to the averaging function when considering
        /// this point mass.
        public var weight: JFloat

        public init(index: Int, weight: JFloat) {
            self.index = index
            self.weight = weight
        }
    }
}
