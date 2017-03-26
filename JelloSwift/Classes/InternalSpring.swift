//
//  InternalSpring.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Represents an internal spring inside a soft body object, and keeps points
/// close together
public struct InternalSpring {
    
    /// First point-mass of the spring.
    /// It's contained in the same body as `pointMassB`.
    public let pointMassA: PointMass
    
    /// Second point-mass of the spring.
    /// It's contained in the same body as `pointMassA`.
    public let pointMassB: PointMass
    
    /// Rest distance of the spring, or the distance the spring tries to
    /// maintain
    public var distance: JFloat = 0
    
    /// The spring coefficient
    public var coefficient: JFloat = 0
    
    /// The spring damping
    public var damping: JFloat = 0
    
    public init(_ pmA: PointMass, _ pmB: PointMass, _ distance: JFloat = 0,
                _ springK: JFloat, _ springD: JFloat) {
        pointMassA = pmA
        pointMassB = pmB
        self.distance = distance
        coefficient = springK
        damping = springD
    }
}
