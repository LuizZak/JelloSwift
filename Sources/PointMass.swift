//
//  PointMass.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Specifies a point mass that composes a body
public struct PointMass: Codable, VectorRepresentable {
    /// The mass of this point mass.
    /// Leave this value always `> 0` to maintain consistency on the simulation,
    /// unless the point is supposed to be fixed.
    /// Values `< 0.2` usually cause inconsistency and instability in the
    /// simulation
    public var mass: JFloat = 1

    /// The global position of the point, in world coordinates
    public var position = Vector2.zero
    /// The global velocity of the point mass
    public var velocity = Vector2.zero
    /// The global force of the point mass
    public var force = Vector2.zero

    /// Normal of this point pointing outwards from the center of the body it's
    /// attached to
    public var normal = Vector2.zero

    /// For VectorRepresentable conformance - returns `self.position`
    @inlinable
    public var vector: Vector2 {
        return position
    }

    public init(mass: JFloat = 0, position: Vector2 = Vector2.zero) {
        self.mass = mass
        self.position = position
    }

    /// Integrates a single physics simulation step for this point mass
    ///
    /// - parameter elapsed: The elapsed time to integrate by, usually in
    /// seconds
    @inlinable
    public mutating func integrate(_ elapsed: JFloat) {
        if mass.isFinite {
            let elapsedMass = elapsed / mass

            velocity += force * elapsedMass
            position += velocity * elapsed
        }

        force = Vector2.zero
    }

    // Applies the given force vector to this point mass
    @inlinable
    public mutating func applyForce(of force: Vector2) {
        self.force += force
    }

    /// Averages a list of point mass positions into one normalized Vector2 point
    @inlinable
    public static func averagePosition<T: Collection>(
        of pointMasses: T
    ) -> Vector2 where T.Iterator.Element == PointMass {
        return pointMasses.averageVector()
    }

    /// Averages a list of point mass velocities into one normalized Vector2 point
    @inlinable
    public static func averageVelocity<T: Collection>(
        of pointMasses: T
    ) -> Vector2 where T.Iterator.Element == PointMass {
        return pointMasses.reduce(Vector2.zero) { $0 + $1.velocity } / JFloat(pointMasses.count)
    }
}
