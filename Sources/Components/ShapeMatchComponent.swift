#if os(macOS) || os(iOS)
    import Darwin.C
#elseif os(Linux)
    import Glibc
#endif

/// Performs shape matching of a soft body to its resting base shape.
public final class ShapeMatchComponent: BodyComponent {
    
    /// Whether the shape matching is on - turning on shape matching will make 
    /// the soft body try to maintain its original shape as specified by its
    /// `baseShape` property
    fileprivate var shapeMatchingOn = true

    /// The target point masses for this shape match component.
    fileprivate var target: Target = .fullShape
    
    /// The spring constant for the shape matching of the body - ignored if
    /// shape matching is off
    fileprivate var shapeSpringK: JFloat = 200
    /// The spring damping for the shape matching of the body - ignored if the
    /// shape matching is off
    fileprivate var shapeSpringDamp: JFloat = 10
    
    public init() {
        
    }
    
    public func prepare(_ body: Body) {
        
    }
    
    /// Sets the shape-matching spring constants
    public func setShapeMatchingConstants(_ springK: JFloat, _ damping: JFloat) {
        shapeSpringK = springK
        shapeSpringDamp = damping
    }
    
    public func accumulateInternalForces(in body: Body, relaxing: Bool) {
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
        
        switch target {
        case .fullShape:
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
        
        case .subset(let indices):
            let (pos, angle) = deriveSubsetPositionAngle(on: body, indices: indices)

            let matrix = Vector2.matrix(
                scalingBy: body.scale,
                rotatingBy: angle,
                translatingBy: pos
            )

            for i in indices {
                let global = body.baseShape[i] * matrix
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

    fileprivate func deriveSubsetPositionAngle(on body: Body, indices: [Int]) -> (position: Vector2, angle: JFloat) {
        let meanPos = body.isPined ? PointMass.averagePosition(of: body.pointMasses) : body.derivedPos
        
        // Find the average angle of all of the masses.
        var angle: JFloat = 0
    
        var originalSign = 1
        var originalAngle: JFloat = 0
        
        let c = body.pointMasses.count
        var first = true
        for index in indices {
            let base = body.baseShape[index]
            let pm = body.pointMasses[index]

            let baseNorm = base.normalized()
            let curNorm  = (pm.position - meanPos).normalized()
            
            var thisAngle = atan2(baseNorm.x * curNorm.y - baseNorm.y * curNorm.x, baseNorm • curNorm)
            
            if first {
                originalSign = (thisAngle >= 0.0) ? 1 : -1
                originalAngle = thisAngle
                
                first = false
            } else {
                let diff = (thisAngle - originalAngle)
                let thisSign = (thisAngle >= 0.0) ? 1 : -1
                
                if abs(diff) > .pi && (thisSign != originalSign) {
                    if thisSign == -1 {
                        thisAngle = .pi + (.pi + thisAngle)
                    } else {
                        thisAngle = (.pi - thisAngle) - .pi
                    }
                }
            }
            
            angle += thisAngle
        }
        
        angle /= JFloat(c)

        return (meanPos, angle)
    }

    /// Used to specify the point masses of the body that should be shape matched
    /// with a `ShapeMatchComponent`.
    public enum Target: Codable {
        /// Shape matching should occur on all point masses of the body.
        case fullShape

        /// Shape matching limited to a subset of the point masses, as specified
        /// by their indices.
        case subset(indices: [Int])
    }
}

/// Creator for the Shape Match component
public struct ShapeMatchComponentCreator: BodyComponentCreator, Codable {
    
    public static var bodyComponentClass: BodyComponent.Type = ShapeMatchComponent.self
    
    /// Whether the shape matching is on - turning on shape matching will make
    /// the soft body try to maintain its original shape as specified by its
    /// baseShape
    public var shapeMatchingOn = true
    
    /// The target point masses for the shape matching. Can either be the full
    /// body or a subset of point masses.
    fileprivate var target: ShapeMatchComponent.Target
    
    /// The spring constant for the shape matching of the body - ignored if
    /// shape matching is off
    public var shapeSpringK: JFloat = 200
    /// The spring damping for the shape matching of the body - ignored if the 
    /// shape matching is off
    public var shapeSpringDamp: JFloat = 10
    
    public init(
        shapeMatchingOn: Bool = true,
        target: ShapeMatchComponent.Target = .fullShape,
        shapeSpringK: JFloat = 200,
        shapeSpringDamp: JFloat = 10
    ) {
        self.shapeMatchingOn = shapeMatchingOn
        self.target = target
        self.shapeSpringK = shapeSpringK
        self.shapeSpringDamp = shapeSpringDamp
    }
    
    public func prepareBodyAfterComponent(_ body: Body) {
        guard let comp = body.component(ofType: ShapeMatchComponent.self) else {
            return
        }
        
        comp.shapeMatchingOn = shapeMatchingOn
        comp.target = target
        comp.setShapeMatchingConstants(shapeSpringK, shapeSpringDamp)
    }
}
