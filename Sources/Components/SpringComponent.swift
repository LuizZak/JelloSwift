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

    /// Gets the total number of springs on this spring component, including both
    /// edge and internal springs
    public var springCount: Int {
        return springs.count
    }

    /// Gets the number of edge springs on the body.
    ///
    /// Edge springs are automatically created.
    public var edgeSpringsCount: Int

    /// The list of internal springs for the body
    fileprivate var springs: [InternalSpring] = []

    /// Whether the shape matching is on - turning on shape matching will make
    /// the soft body try to maintain its original shape as specified by its
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

    public init() {
        edgeSpringsCount = 0
    }

    public func prepare(_ body: Body) {
        clearAllSprings(body)
    }

    /// Adds an internal spring to this body
    @discardableResult
    public func addInternalSpring(
        _ body: Body,
        pointA: Int,
        pointB: Int,
        springK: JFloat,
        damping: JFloat,
        plasticity: SpringPlasticity? = nil
    ) -> InternalSpring {

        let pA = body.pointMasses[pointA]
        let pB = body.pointMasses[pointB]

        let dist = RestDistance.fixed(pA.position.distance(to: pB.position))

        return addInternalSpring(
            body,
            pointA: pointA,
            pointB: pointB,
            springK: springK,
            damping: damping,
            dist: dist,
            plasticity: plasticity
        )
    }

    /// Adds an internal spring to this body
    @discardableResult
    public func addInternalSpring(
        _ body: Body,
        pointA: Int,
        pointB: Int,
        springK: JFloat,
        damping: JFloat,
        dist: RestDistance,
        plasticity: SpringPlasticity? = nil
    ) -> InternalSpring {

        let spring = InternalSpring(pointA, pointB, dist, springK, damping, plasticity)

        springs.append(spring)

        return spring
    }

    /// Clears all the internal springs from the body.
    /// The original edge springs are maintained
    public func clearAllSprings(_ body: Body) {
        springs = []

        buildDefaultSprings(body)
    }

    /// Builds the default edge internal springs for this spring body
    public func buildDefaultSprings(_ body: Body) {
        edgeSpringsCount = body.pointMasses.count

        for i in 0..<edgeSpringsCount {
            let pointB = (i + 1) % edgeSpringsCount
            addInternalSpring(
                body,
                pointA: i, pointB: pointB,
                springK: edgeSpringK, damping: edgeSpringDamp
            )
        }
    }

    /// Sets the shape-matching spring constants
    public func setShapeMatchingConstants(_ springK: JFloat, _ damping: JFloat) {
        shapeSpringK = springK
        shapeSpringDamp = damping
    }

    /// Changes the spring constants for the springs around the shape itself
    /// (edge springs)
    public func setEdgeSpringConstants(
        edgeSpringK: JFloat,
        _ edgeSpringDamp: JFloat
    ) {
        // we know that the first n springs in the list are the edge springs.
        for i in 0..<edgeSpringsCount {
            springs[i].coefficient = edgeSpringK
            springs[i].damping = edgeSpringDamp
        }
    }

    /// Sets the spring constant for the given spring index.
    /// The spring index starts from pointMasses.count and onwards, so the first
    /// spring will not be the first edge spring.
    public func setSpringConstants(
        forSpringIndex springID: Int,
        _ springK: JFloat,
        _ springDamp: JFloat
    ) {
        // index is for all internal springs, AFTER the default edge springs.
        let index = edgeSpringsCount + springID

        springs[index].coefficient = springK
        springs[index].damping = springDamp
    }

    /// Sets the rest distance for the given spring index.
    /// The spring index starts from pointMasses.count and onwards, so the first
    /// spring will not be the first edge spring.
    public func setSpringRestDistance(forSpringIndex springID: Int, _ dist: RestDistance) {
        // index is for all internal springs, AFTER the default internal springs.
        let index = edgeSpringsCount + springID

        springs[index].restDistance = dist
    }

    /// Gets the rest distance for the given spring index.
    /// This ignores the default edge springs, so the index is always
    /// `+ body.pointMasses.count`
    public func springRestDistance(forSpringIndex springID: Int) -> RestDistance {
        return springs[edgeSpringsCount + springID].restDistance
    }

    /// Gets the spring constant of a spring at the specified index.
    /// This ignores the default edge springs, so the index is always
    /// `+ body.pointMasses.count`
    public func springCoefficient(forSpringIndex springID: Int) -> JFloat {
        return springs[edgeSpringsCount + springID].coefficient
    }

    /// Gets the spring damping of a spring at the specified index
    /// This ignores the default edge springs, so the index is always
    /// `+ body.pointMasses.count`
    public func springDamping(forSpringIndex springID: Int) -> JFloat {
        return springs[edgeSpringsCount + springID].damping
    }

    /// Gets the current plasticity settings of a spring, or nil, if no plasticity
    /// is set.
    /// This ignores the default edge springs, so the index is always
    /// `+ body.pointMasses.count`
    public func springPlasticity(forSpringIndex springID: Int) -> SpringPlasticity? {
        return springs[edgeSpringsCount + springID].plasticity
    }

    /// Sets the current plasticity settings of a spring, or disables it, if `nil`
    /// is passed.
    ///
    /// This ignores the default edge springs, so the index is always
    /// `+ body.pointMasses.count`
    public func setSpringPlasticity(
        forSpringIndex springID: Int,
        plasticity: SpringPlasticity?
    ) {
        springs[edgeSpringsCount + springID].plasticity = plasticity
    }

    public func accumulateInternalForces(in body: Body, relaxing: Bool) {
        for (i, s) in springs.enumerated() {
            let p1 = body.pointMasses[s.pointMassA]
            let p2 = body.pointMasses[s.pointMassB]

            let actDist = p1.position.distance(to: p2.position)

            let force =
                calculateSpringForce(
                    posA: p1.position, velA: p1.velocity,
                    posB: p2.position, velB: p2.velocity,
                    distance: s.restDistance.clamp(value: actDist),
                    springK: s.coefficient, springD: s.damping
                )

            body.applyForce(force, toPointMassAt: s.pointMassA)
            body.applyForce(-force, toPointMassAt: s.pointMassB)

            if !relaxing && s.plasticity != nil {
                // Apply plasticity
                var s = s
                s.updatePlasticity(distance: actDist)
                springs[i] = s
            }
        }

        if shapeMatchingOn && shapeSpringK > 0 {
            applyShapeMatching(on: body)
        }
    }

    public func accumulateExternalForces(on body: Body, world: World, relaxing: Bool) {

    }

    /// Applies shape-matching on the given body.
    /// Shape-matching applies spring forces to each point masses on the
    /// direction of the body's original global shape
    fileprivate func applyShapeMatching(on body: Body) {

        let matrix = Vector2.matrix(
            scalingBy: body.scale,
            rotatingBy: body.derivedAngle,
            translatingBy: body.derivedPos
        )

        body.baseShape.transformVertices(&body.globalShape, matrix: matrix)

        for (global, i) in zip(body.globalShape, 0..<body.pointMasses.count) {
            let p = body.pointMasses[i]
            let velB = body.isKinematic ? .zero : p.velocity

            let force = calculateSpringForce(
                posA: p.position, velA: p.velocity,
                posB: global, velB: velB,
                distance: 0.0,
                springK: shapeSpringK,
                springD: shapeSpringDamp
            )

            body.applyForce(force, toPointMassAt: i)
        }
    }
}

/// Creator for the Spring component
public struct SpringComponentCreator: BodyComponentCreator, Codable {

    public static var bodyComponentClass: BodyComponent.Type = SpringComponent.self

    /// Whether the shape matching is on - turning on shape matching will make
    /// the soft body try to maintain its original shape as specified by its
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
    public var innerSprings: [InternalSpring] = []

    public init(
        shapeMatchingOn: Bool = true,
        edgeSpringK: JFloat = 50, edgeSpringDamp: JFloat = 2,
        shapeSpringK: JFloat = 200, shapeSpringDamp: JFloat = 10,
        innerSprings: [InternalSpring] = []
    ) {
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

        comp.setEdgeSpringConstants(edgeSpringK: edgeSpringK, edgeSpringDamp)
        comp.setShapeMatchingConstants(shapeSpringK, shapeSpringDamp)

        for element in innerSprings {
            comp.addInternalSpring(
                body,
                pointA: element.pointMassA,
                pointB: element.pointMassB,
                springK: element.coefficient,
                damping: element.damping,
                dist: element.restDistance
            )
        }
    }
}
