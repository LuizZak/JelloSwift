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
    public let pointMassA: Int
    
    /// Second point-mass of the spring.
    /// It's contained in the same body as `pointMassA`.
    public let pointMassB: Int
    
    /// Rest distance of the spring, or the distance the spring tries to
    /// maintain
    public var restDistance: RestDistance = 0
    
    /// Initial resting distance of the spring, ignoring any plasticity deformations.
    /// This value matches the initial `restDistance` value set during spring
    /// creation.
    public var initialRestDistance: RestDistance = 0
    
    /// Specifies the plasticity properties of this spring.
    public var plasticity: Plasticity?
    
    /// Rest distance of the spring, or the distance the spring tries to
    /// maintain
    public var distance: JFloat {
        get {
            return restDistance.maximumDistance
        }
        set {
            restDistance = .fixed(newValue)
            initialRestDistance = restDistance
        }
    }
    
    /*
     mSpringStrength = springStrength;
     //std::cout << "restLengthPRE: " << mRestLength << "\n";
     ci::Vec2f dir = particleA->mPos - particleB->mPos;
     float dirLength = dir.length();
     float dirLengthSqrd = dir.lengthSquared();
     
     
     float d = mYieldRatio * mRestLength;
     if ( dirLength > mRestLength + d ){
     mRestLength += mPlasticityConstant * ( dirLength - mRestLength - d );
     }
     else if ( dirLength < mRestLength - d ){
     mRestLength -= mPlasticityConstant * ( mRestLength - d - dirLength );
     }
 */
    
    /// The spring coefficient
    public var coefficient: JFloat = 0
    
    /// The spring damping
    public var damping: JFloat = 0
    
    @available(*, deprecated, message: "Use self.init(_:PointMass,_:PointMass,_:RestDistance,_:JFloat,_:JFloat) instead")
    public init(_ pmA: Int, _ pmB: Int, _ distance: JFloat = 0,
                _ springK: JFloat, _ springD: JFloat) {
        pointMassA = pmA
        pointMassB = pmB
        self.distance = distance
        coefficient = springK
        damping = springD
    }
    
    public init(_ pmA: Int, _ pmB: Int, _ distance: RestDistance = 0,
                _ springK: JFloat, _ springD: JFloat) {
        pointMassA = pmA
        pointMassB = pmB
        self.restDistance = distance
        initialRestDistance = distance
        coefficient = springK
        damping = springD
    }
    
    /// Specifies plasticity properties of a spring
    public struct Plasticity {
        /// Ratio (of resting distance vs actual length) before plasticity starts
        /// to change the resting length of the spring, deforming it permanently.
        public var yieldRatio: JFloat = 0
        
        /// Plasticity rate for the spring.
        /// When the rest distance of a spring goes past its yield limit, the
        /// resting distance of the spring is stretched so it deforms 'plastically'
        /// by adapting the resting length to be the resulting factor between the
        /// rest length and the actual length, times this rate.
        ///
        /// e.g. given a spring with a resting distance `R = 10`, a plasticity
        /// rate `P = 0.5`, a yield ratio of `Y = 0.5`, and an actual length `L`,
        /// if `L / R > Y` or `R / L < 1 / Y`, the resting length will be updated
        /// to be `R = L / R * P`.
        public var rate: JFloat = 0.5
    }
}
