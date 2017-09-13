//
//  SpringComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

/// Represents a Spring component that can be added to a body to include 
/// spring-based physics in the body's point masses
public final class SpringComponent: BodyComponent {
    
    /// Gets the count of springs on this spring component
    public var springCount: Int {
        return springs.count
    }
    
    /// The list of internal springs for the body
    fileprivate var springs: [InternalSpring] = []
    
    /// Whether the shape matching is on - turning on shape matching will make 
    /// the soft body try to mantain its original shape as specified by its
    /// `baseShape` property
    fileprivate var shapeMatchingOn = true
    
    /// The spring constant for the edges of the spring body
    fileprivate var edgeSpringK: JFloat = 50
    /// The spring damping for the edges of the spring body
    fileprivate var edgeSpringDamp: JFloat = 2
    
    /// The spring constant for the shape matching of the body - ignored if
    /// shape matching is off
    fileprivate var shapeSpringK: JFloat = 200
    /// The spring damping for the shape matching of the body - ignored if the
    /// shape matching is off
    fileprivate var shapeSpringDamp: JFloat = 10
    
    public init(body: Body) {
        
    }
    
    public func prepare(_ body: Body) {
        clearAllSprings(body)
    }
    
    /// Adds an internal spring to this body
    @discardableResult
    public func addInternalSpring(_ body: Body, pointA: Int, pointB: Int,
                                  springK: JFloat, damping: JFloat) -> InternalSpring {
        let pA = body.pointMasses[pointA]
        let pB = body.pointMasses[pointB]
        
        let dist = RestDistance.fixed(pA.position.distance(to: pB.position))
        
        let spring = InternalSpring(pointA, pointB, dist, springK, damping)
        
        springs.append(spring)
        
        return spring
    }
    
    /// Adds an internal spring to this body
    @available(*, deprecated, message: "Use addInternalSpring(:Body:Int:Int:JFloat:JFloat:RestDistance) instead.")
    @discardableResult
    public func addInternalSpring(_ body: Body, pointA: Int, pointB: Int,
                                  springK: JFloat, damping: JFloat,
                                  dist: JFloat) -> InternalSpring {
        let spring = InternalSpring(pointA, pointB, dist, springK, damping)
        
        springs.append(spring)
        
        return spring
    }
    
    /// Adds an internal spring to this body
    @discardableResult
    public func addInternalSpring(_ body: Body, pointA: Int, pointB: Int,
                                  springK: JFloat, damping: JFloat,
                                  dist: RestDistance) -> InternalSpring {
        let dist = dist
        
        let spring = InternalSpring(pointA, pointB, dist, springK, damping)
        
        springs.append(spring)
        
        return spring
    }
    
    /// Clears all the internal springs from the body.
    /// The original edge springs are mantained
    public func clearAllSprings(_ body: Body) {
        springs = []
        
        buildDefaultSprings(body)
    }
    
    /// Builds the default edge internal springs for this spring body
    public func buildDefaultSprings(_ body: Body) {
        for i in 0..<body.pointMasses.count {
            let pointB = (i + 1) % body.pointMasses.count
            addInternalSpring(body, pointA: i, pointB: pointB,
                              springK: edgeSpringK, damping: edgeSpringDamp)
        }
    }
    
    /// Sets the shape-matching spring constants
    public func setShapeMatchingConstants(_ springK: JFloat, _ damping: JFloat) {
        shapeSpringK = springK
        shapeSpringDamp = damping
    }
    
    /// Changes the spring constants for the springs around the shape itself 
    /// (edge springs)
    public func setEdgeSpringConstants(_ body: Body, edgeSpringK: JFloat,
                                       _ edgeSpringDamp: JFloat) {
        // we know that the first n springs in the list are the edge springs.
        for i in 0..<body.pointMasses.count {
            springs[i].coefficient = edgeSpringK
            springs[i].damping = edgeSpringDamp
        }
    }
    
    /// Sets the spring constant for the given spring index.
    /// The spring index starts from pointMasses.count and onwards, so the first
    /// spring will not be the first edge spring.
    public func setSpringConstants(forSpringIndex springID: Int, in body: Body,
                                   _ springK: JFloat, _ springDamp: JFloat) {
        // index is for all internal springs, AFTER the default internal springs.
        let index = body.pointMasses.count + springID
        
        springs[index].coefficient = springK
        springs[index].damping = springDamp
    }
    
    /// Sets the rest distance for the givne spring index.
    /// The spring index starts from pointMasses.count and onwards, so the first
    /// spring will not be the first edge spring.
    public func setSpringRestDistance(forSpringIndex springID: Int, in body: Body, _ dist: RestDistance) {
        // index is for all internal springs, AFTER the default internal springs.
        let index = body.pointMasses.count + springID
        
        springs[index].restDistance = dist
    }
    
    /// Gets the rest distance for the givne spring index.
    /// This ignores the default edge springs, so the index is always
    /// `+ body.pointMasses.count`
    public func springRestDistance(forSpringIndex springID: Int, in body: Body) -> RestDistance {
        return springs[body.pointMasses.count + springID].restDistance
    }
    
    /// Gets the spring constant of a spring at the specified index.
    /// This ignores the default edge springs, so the index is always 
    /// `+ body.pointMasses.count`
    public func springCoefficient(forSpringIndex springID: Int, in body: Body) -> JFloat {
        return springs[body.pointMasses.count + springID].coefficient
    }
    
    /// Gets the spring damping of a spring at the specified index
    /// This ignores the default edge springs, so the index is always 
    /// `+ body.pointMasses.count`
    public func springDamping(forSpringIndex springID: Int, in body: Body) -> JFloat {
        return springs[body.pointMasses.count + springID].damping
    }
    
    /// Gets the current plasticity settings of a spring, or nil, if no plasticity
    /// is set.
    /// This ignores the default edge springs, so the index is always
    /// `+ body.pointMasses.count`
    public func springPlasticity(forSpringIndex springID: Int, in body: Body) -> InternalSpring.Plasticity? {
        return springs[body.pointMasses.count + springID].plasticity
    }
    
    /// Sets the current plasticity settings of a spring, or disables it, if `nil`
    /// is passed.
    ///
    /// This ignores the default edge springs, so the index is always
    /// `+ body.pointMasses.count`
    public func setSpringPlasticity(forSpringIndex springID: Int, in body: Body,
                                    plasticity: InternalSpring.Plasticity?) {
        springs[body.pointMasses.count + springID].plasticity = plasticity
    }
    
    public func accumulateInternalForces(in body: Body, relaxing: Bool) {
        for (i, s) in springs.enumerated() {
            let p1 = body.pointMasses[s.pointMassA]
            let p2 = body.pointMasses[s.pointMassB]
            
            let force: Vector2
            
            let actDist = p1.position.distance(to: p2.position)
            
            switch s.restDistance {
            case .fixed(let dist):
                force =
                    calculateSpringForce(posA: p1.position, velA: p1.velocity,
                                         posB: p2.position, velB: p2.velocity,
                                         distance: dist,
                                         springK: s.coefficient, springD: s.damping)
            case .ranged:
                force =
                    calculateSpringForce(posA: p1.position, velA: p1.velocity,
                                         posB: p2.position, velB: p2.velocity,
                                         distance: s.restDistance.clamp(value: actDist),
                                         springK: s.coefficient, springD: s.damping)
            }
            
            p1.applyForce(of: force)
            p2.applyForce(of: -force)
            
            if !relaxing {
                // Apply plasticity
                var s = s
                s.updatePlasticity(distance: actDist)
                springs[i] = s
            }
        }
        
        if(shapeMatchingOn && shapeSpringK > 0) {
            applyShapeMatching(on: body)
        }
    }
    
    /// Applies shape-matching on the given body.
    /// Shape-matching applies spring forces to each point masses on the
    /// direction of the body's original global shape
    fileprivate func applyShapeMatching(on body: Body) {
        
        let matrix = Vector2.matrix(scalingBy: body.scale,
                                    rotatingBy: body.derivedAngle,
                                    translatingBy: body.derivedPos)
        
        body.baseShape.transformVertices(&body.globalShape, matrix: matrix)
        
        for (global, p) in zip(body.globalShape, body.pointMasses) {
            let velB = body.isKinematic ? Vector2.zero : p.velocity
            
            let force = calculateSpringForce(posA: p.position, velA: p.velocity,
                                             posB: global, velB: velB,
                                             distance: 0.0,
                                             springK: shapeSpringK,
                                             springD: shapeSpringDamp)
            
            p.applyForce(of: force)
        }
    }
}

/// Creator for the Spring component
public struct SpringComponentCreator: BodyComponentCreator, Codable {
    
    public static var bodyComponentClass: BodyComponent.Type = SpringComponent.self
    
    /// Whether the shape matching is on - turning on shape matching will make
    /// the soft body try to mantain its original shape as specified by its
    /// baseShape
    public var shapeMatchingOn = true
    
    /// The spring constant for the edges of the spring body
    public var edgeSpringK: JFloat = 50
    /// The spring damping for the edges of the spring body
    public var edgeSpringDamp: JFloat = 2
    
    /// The spring constant for the shape matching of the body - ignored if
    /// shape matching is off
    public var shapeSpringK: JFloat = 200
    /// The spring damping for the shape matching of the body - ignored if the 
    /// shape matching is off
    public var shapeSpringDamp: JFloat = 10
    
    /// An array of inner springs for a body
    public var innerSprings: [SpringComponentInnerSpring] = []
    
    public init(shapeMatchingOn: Bool = true,
                edgeSpringK: JFloat = 50, edgeSpringDamp: JFloat = 2,
                shapeSpringK: JFloat = 200, shapeSpringDamp: JFloat = 10,
                innerSprings: [SpringComponentInnerSpring] = []) {
        self.shapeMatchingOn = shapeMatchingOn
        
        self.edgeSpringK = edgeSpringK
        self.edgeSpringDamp = edgeSpringDamp
        
        self.shapeSpringK = shapeSpringK
        self.shapeSpringDamp = shapeSpringDamp
        
        self.innerSprings = innerSprings
    }
    
    public func prepareBodyAfterComponent(_ body: Body) {
        guard let comp = body.component(ofType: SpringComponent.self) else {
            return
        }
        
        comp.shapeMatchingOn = shapeMatchingOn
        
        comp.setEdgeSpringConstants(body, edgeSpringK: edgeSpringK, edgeSpringDamp)
        comp.setShapeMatchingConstants(shapeSpringK, shapeSpringDamp)
        
        for element in innerSprings {
            comp.addInternalSpring(body, pointA: element.indexA,
                                   pointB: element.indexB,
                                   springK: element.coefficient,
                                   damping: element.damping,
                                   dist: element.restDistance)
        }
    }
}

/// Specifies a template for an inner spring
public struct SpringComponentInnerSpring: Codable {
    
    /// Index of the first point mass of the spring, in the `pointMasses` 
    /// property of the target body
    public var indexA = 0
    /// Index of the second point mass of the spring, in the `pointMasses` 
    /// property of the target body
    public var indexB = 0
    
    /// The spring coefficient for this spring
    public var coefficient: JFloat = 0
    /// Damping coefficient for this spring
    public var damping: JFloat = 0
    
    /// The rest distance for this spring, as in, the distance this spring will
    /// try to mantain between the two point masses.
    public var restDistance: RestDistance = .fixed(-1)
    
    /// The rest distance for this spring, as in, the distance this spring will
    /// try to mantain between the two point masses.
    @available(*, deprecated, message: "Use SpringComponentInnerSpring.restDistance instead")
    public var dist: JFloat {
        get {
            return restDistance.maximumDistance
        }
        set {
            restDistance = .fixed(newValue)
        }
    }
    
    public init(a: Int, b: Int, coefficient: JFloat, damping: JFloat) {
        indexA = a
        indexB = b
        
        self.coefficient = coefficient
        self.damping = damping
    }
    
    @available(*, deprecated, message: "Use init(a:b:coefficient:damping:restDistance:) instead")
    public init(a: Int, b: Int, coefficient: JFloat, damping: JFloat,
                dist: JFloat) {
        indexA = a
        indexB = b
        
        self.coefficient = coefficient
        self.damping = damping
        
        self.restDistance = .fixed(dist)
    }
    
    public init(a: Int, b: Int, coefficient: JFloat, damping: JFloat,
                restDistance: RestDistance = -1) {
        indexA = a
        indexB = b
        
        self.coefficient = coefficient
        self.damping = damping
        
        self.restDistance = restDistance
    }
}
