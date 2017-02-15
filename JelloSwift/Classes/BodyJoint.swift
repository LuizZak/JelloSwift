//
//  BodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import Foundation
import CoreGraphics

public func ==(lhs: BodyJoint, rhs: BodyJoint) -> Bool {
    return lhs === rhs
}

/// Base class for joints which unites two separate bodies
open class BodyJoint: Equatable {
    
    /// Gets the first link that contins informationa bout the first body linked by this joint
    public final let bodyLink1: JointLinkType
    /// Gets the second link that contins informationa bout the first body linked by this joint
    public final let bodyLink2: JointLinkType
    
    /// Whether to allow collisions between the two objects joined by this BodyJoint.
    /// Defaults to false
    open var allowCollisions = false
    
    /// Controls whether this valubody joint is enabled.
    /// Disabling body joints disables all of the physics of the joint.
    /// Note that collisions between bodies are still governed by .allowCollisions even if the joint is disabled
    open var enabled = true
    
    /// Gets or sets the rest distance for this joint
    /// In case the rest distance represents a ranged distance (RestDistance.ranged), the joint only applies
    /// forces if the distance between the links is dist > restDistance.min && dist < restDistance.max
    open var restDistance: RestDistance
    
    /// Initializes a body joint on a given world, linking the two given links.
    /// Optionally provides the distance.
    /// In case the distance was not provided, it will be automatically calculated based off of the position of each
    /// link.
    public init(on world: World, link1: JointLinkType, link2: JointLinkType, distance: RestDistance? = nil) {
        bodyLink1 = link1
        bodyLink2 = link2
        
        // Automatic distance calculation
        restDistance = distance ?? .fixed(link1.position.distance(to: link2.position))
    }
    
    /**
     * Resolves this joint
     *
     * - parameter dt: The delta time to update the resolve on
     */
    open func resolve(_ dt: CGFloat) {
        
    }
    
    /// Specifies a rest distance for a body joint.
    /// Distances can either by fixed by a distance, or ranged
    /// so the body joint only applies within a specified range
    public enum RestDistance: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
        
        /// Fixed distance
        case fixed(CGFloat)
        
        /// Distance is ranged between a minimum and maximum value
        case ranged(min: CGFloat, max: CGFloat)
        
        /// Returns the minimum distance for this rest distance.
        /// If the current value is .fixed, this method always returns the rest
        /// distance it represents, if .ranged, it returns its min value
        public var minimumDistance: CGFloat {
            switch(self) {
            case .fixed(let value),
                 .ranged(let value, _):
                return value
            }
        }
        
        /// Returns the maximum distance for this rest distance.
        /// If the current value is .fixed, this method always returns the rest
        /// distance it represents, if .ranged, it returns its max value
        public var maximumDistance: CGFloat {
            switch(self) {
            case .fixed(let value),
                 .ranged(_, let value):
                return value
            }
        }
        
        public init(integerLiteral value: Int) {
            self = .fixed(CGFloat(value))
        }
        
        public init(floatLiteral value: Double) {
            self = .fixed(CGFloat(value))
        }
        
        /// Returns whether a given range is within the range of this rest distance.
        /// If the current value is .fixed, this does an exact equality operation,
        /// if .ranged, it performs `value > min && value < max`
        public func inRange(value: CGFloat) -> Bool {
            switch(self) {
            case .fixed(let d):
                return value == d
            case .ranged(let min, let max):
                return value > min && value < max
            }
        }
        
        /// Clamps a given value to be within the range of this rest distance.
        /// If the current value is .fixed, this method always returns the rest
        /// distance it represents, if .ranged, it performs
        /// `max(minValue, min(maxValue, value))`
        public func clamp(value: CGFloat) -> CGFloat {
            switch(self) {
            case .fixed(let d):
                return d
            case .ranged(let min, let max):
                return Swift.max(min, Swift.min(max, value))
            }
        }
    }
}

/// Helper operator for creating a body's rest distance
public func ...(lhs: CGFloat, rhs: CGFloat) -> BodyJoint.RestDistance {
    return .ranged(min: lhs, max: rhs)
}

/// Protocol to be implemented by objects that specify the way a joint links with a body
public protocol JointLinkType {
    
    /// Gets the body that this joint link is linked to
    unowned var body: Body { get }
    
    /// Gets the type of joint this joint link represents
    var linkType: LinkType { get }
    
    /// Gets the position, in world coordinates, at which this joint links with the underlying body
    var position: Vector2 { get }
    
    /// Gets the velocity of the object this joint links to
    var velocity: Vector2 { get }
    
    /// Gets the total mass of the subject of this joint link
    var mass: CGFloat { get }
    
    /// Gets a value specifying whether the object referenced by this JointLinkType is static
    var isStatic: Bool { get }
    
    /// Appies a given force to the subject of this joint link
    ///
    /// - parameter force: A force to apply to the subjects of this joint link
    func applyForce(of force: Vector2)
}

/// The type of joint link of a BodyJointLink class
public enum LinkType {
    /// Specifies that the joint links at the whole body, relative to the center
    case body
    /// Specifies that the joint links at a body's point
    case point
    /// Specifies that the joint links at a body's edge (set of two points)
    case edge
    /// Specifies that the joint links at an arbitrary set of points of a body
    case shape
}
