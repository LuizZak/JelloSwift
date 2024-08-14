//
//  BodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Base class for joints which unites two separate bodies
open class BodyJoint: Equatable {

    /// Gets the first link that contains information about the first body linked
    /// by this joint
    public final let bodyLink1: JointLink
    /// Gets the second link that contains information about the first body
    /// linked by this joint
    public final let bodyLink2: JointLink

    /// Whether to allow collisions between the two objects joined by this
    /// BodyJoint.
    /// Defaults to false.
    open var allowCollisions = false

    /// Controls whether this body joint is enabled.
    /// Disabling body joints disables all of the physics of the joint.
    /// Note that collisions between bodies are still governed by
    /// `.allowCollisions` even if the joint is disabled.
    open var enabled = true

    /// Initializes a body joint on a given world, linking the two given links.
    /// Optionally provides the distance.
    public init(on world: World, link1: JointLink, link2: JointLink) {
        bodyLink1 = link1
        bodyLink2 = link2
    }

    /// Resolves this joint
    ///
    /// - Parameter dt: The delta time to update the resolve on
    open func resolve(_ dt: JFloat) {

    }

    public static func == (lhs: BodyJoint, rhs: BodyJoint) -> Bool {
        return lhs === rhs
    }
}
