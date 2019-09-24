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
    public var restDistance: RestDistance = 0 {
        didSet {
            restDistanceSquared = restDistance.squared()
        }
    }
    
    /// Initial resting distance of the spring, ignoring any plasticity deformations.
    /// This value matches the initial `restDistance` value set during spring
    /// creation.
    public var initialRestDistance: RestDistance = 0 {
        didSet {
            initialRestDistanceSquared = initialRestDistance.squared()
        }
    }
    
    /// Specifies the plasticity properties of this spring.
    /// If `nil`, plasticity is disabled and spring never deforms permanently.
    public var plasticity: SpringPlasticity?
    
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
    
    /// The rest distance of this spring, squared.
    /// Always the square of the current `restDistance`, and updated automatically
    /// whehever `restDistance` is set.
    private(set) var restDistanceSquared: RestDistance = 0
    
    /// The initial rest distance of this spring, squared.
    /// Always the square of the current `initialRestDistanceSquared`, and updated
    /// automatically whehever `initialRestDistanceSquared` is set.
    private(set) var initialRestDistanceSquared: RestDistance = 0
    
    /// The spring coefficient
    public var coefficient: JFloat = 0
    
    /// The spring damping
    public var damping: JFloat = 0
    
    public init(_ pmA: Int,
                _ pmB: Int,
                _ distance: RestDistance = 0,
                _ springK: JFloat,
                _ springD: JFloat,
                _ plasticity: SpringPlasticity? = nil) {
        
        pointMassA = pmA
        pointMassB = pmB
        self.restDistance = distance
        initialRestDistance = distance
        coefficient = springK
        damping = springD
        self.plasticity = plasticity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        try pointMassA = container.decode(Int.self, forKey: .pointMassA)
        try pointMassB = container.decode(Int.self, forKey: .pointMassB)
        try restDistance = container.decode(RestDistance.self, forKey: .restDistance)
        try initialRestDistance = container.decode(RestDistance.self, forKey: .initialRestDistance)
        try coefficient = container.decode(JFloat.self, forKey: .coefficient)
        try damping = container.decode(JFloat.self, forKey: .damping)
        
        restDistanceSquared = restDistance.squared()
        initialRestDistanceSquared = initialRestDistance.squared()
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
        
        restDistance =
            calculatePlasticity(distance: distance, restDistance: restDistance,
                                initialRestDistance: initialRestDistance,
                                plasticity: plas)
    }
    
    private enum CodingKeys: String, CodingKey {
        case pointMassA
        case pointMassB
        case restDistance
        case initialRestDistance
        case coefficient
        case damping
    }
}


/// Specifies plasticity properties of a spring.
///
/// Plasticity permanently affects a spring's rest length by modifying it
/// when its length is stretched beyond a certain limit.
public struct SpringPlasticity: Codable {
    /// Ratio (of resting distance vs actual length) before plasticity starts
    /// to change the resting length of the spring, deforming it permanently.
    public var yieldRatio: JFloat = 0.3
    
    /// Plasticity rate for the spring.
    /// When the rest distance of a spring goes past its yield limit, the
    /// resting distance of the spring is stretched so it deforms 'plastically'
    /// by adapting the resting length to be the resulting factor between the
    /// rest length and the actual length, times this rate.
    ///
    /// if `L / R > Y` or `R / L < 1 / Y`, the resting length will be updated
    /// to be `R += P * (L - R - (Y * R))` (for `L > R`) or `R -= P * (R - (Y * R) - L)`
    /// (for `L < R`).
    ///
    /// e.g. given a spring with a resting distance `R = 10`, a plasticity
    /// rate `P = 0.5`, a yield ratio of `Y = 0.3`, and an actual length `L = 15`,
    /// the resulting `R` would be `R = 10 + (0.5 * (15 - 10 - (0.3 * 10)))` ->
    /// `R = 10 + 1` -> `R = 11`.
    public var rate: JFloat = 0.5
    
    /// A factor limit at which the plasticity stops affecting the rest length
    /// of the spring beyond its initial rest length.
    ///
    /// If the rest length of a spring goes `R > IL * limit` (with `IL` being
    /// the initial length), or `R < IL / limit`, the plasticity does not
    /// take effect.
    public var limit: JFloat = 2
    
    public init(yieldRatio: JFloat = 0.3, rate: JFloat = 0.5, limit: JFloat = 2) {
        self.yieldRatio = yieldRatio
        self.rate = rate
        self.limit = limit
    }
}
