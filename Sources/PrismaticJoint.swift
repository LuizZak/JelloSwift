//
//  PrismaticBodyJoint.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 06/03/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

/// Represents a joint that links two joint links along an angled axis.
open class PrismaticBodyJoint: BodyJoint {
    
    /// The spring coefficient for this spring body joint
    public var springCoefficient: JFloat
    
    /// The spring damping for this spring body joint
    public var springDamping: JFloat
    
    /// Optional plasticity information.
    /// If not provided, spring body joint does not undergo plasticity deformations.
    public var plasticity: SpringPlasticity?
    
    /// The reference angle at which the two joints link.
    public var referenceAngle: JFloat
    
    /// In case spring plasticity is available, this is used to limit plasticity
    /// effects.
    var initialRestDistance: RestDistance
    
    public init(on world: World,
                link1: JointLink,
                link2: JointLink,
                coefficient: JFloat,
                damping: JFloat,
                referenceAngle: JFloat,
                distance: RestDistance? = nil,
                plasticity: SpringPlasticity? = nil) {
        
        self.springCoefficient = coefficient
        self.springDamping = damping
        self.plasticity = plasticity
        self.referenceAngle = referenceAngle
        self.initialRestDistance = 0
        
        super.init(on: world, link1: link1, link2: link2, distance: distance)
        
        self.initialRestDistance = restDistance
    }

    open override func resolve(_ dt: JFloat) {
        // TODO: Implement prismatic joint
    }
}
