//
//  InternalSpring.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Represents an internal spring inside a soft body object, and keeps points
/// close together
public struct InternalSpring: Codable {
    
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
    /// If `nil`, plasticity is disabled and spring never deforms permanently.
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
    
    /// Updates the plasticity settings of this spring.
    /// Does nothing, if plasticity is not configured.
    ///
    /// - Parameters:
    ///   - distance: The current distance between the points
    public mutating func updatePlasticity(distance: JFloat) {
        guard let plas = plasticity else {
            return
        }
        
        if restDistance.inRange(value: distance) { // Exact distance - no plasticity changes
            return
        }
        
        // Based on source code found at:
        // https://github.com/justincouch/cinderFluid/blob/a07cc282d36c37d1bd782a36d6ffaf4c801334eb/Fluid/xcode/Spring.cpp#L46
        //
        if distance > restDistance.maximumDistance {
            
            let d = plas.yieldRatio * restDistance.maximumDistance
            
            if distance > restDistance.maximumDistance + d {
                restDistance.maximumDistance += plas.rate * (distance - restDistance.maximumDistance - d)
                
                if restDistance.maximumDistance > initialRestDistance.maximumDistance * plas.limit {
                    restDistance.maximumDistance = initialRestDistance.maximumDistance * plas.limit
                }
            }
            
        } else if distance < restDistance.minimumDistance {
            
            let d = plas.yieldRatio * restDistance.minimumDistance
            
            if distance < restDistance.minimumDistance - d {
                restDistance.minimumDistance -= plas.rate * (restDistance.minimumDistance - d - distance)
                
                if restDistance.minimumDistance < initialRestDistance.minimumDistance / plas.limit {
                    restDistance.minimumDistance = initialRestDistance.minimumDistance / plas.limit
                }
            }
        }
    }
    
    /// Specifies plasticity properties of a spring.
    ///
    /// Plasticity permanently affects a spring's rest length by modifying it
    /// when its length is stretched beyond a certain limit.
    public struct Plasticity {
        /// Ratio (of resting distance vs actual length) before plasticity starts
        /// to change the resting length of the spring, deforming it permanently.
        public var yieldRatio: JFloat = 0.3
        
        /// Plasticity rate for the spring.
        /// When the rest distance of a spring goes past its yield limit, the
        /// resting distance of the spring is stretched so it deforms 'plastically'
        /// by adapting the resting length to be the resulting factor between the
        /// rest length and the actual length, times this rate.
        ///
        /// e.g. given a spring with a resting distance `R = 10`, a plasticity
        /// rate `P = 0.5`, a yield ratio of `Y = 0.5`, and an actual length `L`,
        /// if `L / R > Y` or `R / L < 1 / Y`, the resting length will be updated
        /// to be `R += P * (L - R - (Y * R))` (for `L > R`) or `R -= P * (R - (Y * R) - L)`
        /// (for `L < R`).
        public var rate: JFloat = 0.5
        
        /// A factor limit at which the plasticity stops affecting the rest length
        /// of the spring beyond its initial rest length.
        ///
        /// If the rest length of a spring goes `R > IL * limit` (with `IL` being
        /// the initial length), or `R < IL / limit`, the plasticity does not
        /// take effect.
        public var limit: JFloat = 2
    }
}
