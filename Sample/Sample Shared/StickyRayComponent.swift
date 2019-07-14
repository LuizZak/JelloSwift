import Foundation
import JelloSwift

class StickyRayComponent: BodyRayComponent {
    /// A function that is used to derive the strength of the 'stickiness' of the
    /// rays casted from the body.
    ///
    /// The function receives a normalized value that indicates the length of
    /// the ray, and should return a normalized value for the strength of the
    /// stickiness effect.
    var rayStickyFunction: (JFloat) -> JFloat = { $0 }
    
    var springCoefficient: JFloat = 100
    var springDampness: JFloat = 10
    
    override func accumulateExternalForces(on body: Body, world: World, relaxing: Bool) {
        // Apply sticky rays to other bodies
        for point in body.pointMasses {
            let vertex = point.position
            let normal = point.normal
            
            let start = vertex - normal * 0.1
            let end = vertex + normal * rayLength
            
            let rayResult
                = world.rayCast(from: start,
                                to: end,
                                ignoreTest: { [ignoreJoinedBodies] in $0 === body || (ignoreJoinedBodies && world.areBodiesJoined(body, $0)) })
            
            guard let (pt, hitBody) = rayResult else {
                continue
            }
            guard let edgeHit = hitBody.closestEdge(to: pt) else {
                continue
            }
            
            let normalizedDistance
                = clamp(pt.distance(to: start) / rayLength,
                        minimum: 0, maximum: 1)
            
            let strength = rayStickyFunction(normalizedDistance)
            
            let edgeVelocity
                = edgeHit.edgePoint1
                    .velocity
                    .ratio(edgeHit.edgeRatio, to: edgeHit.edgePoint2.velocity)
            
            let force =
                calculateSpringForce(posA: vertex,
                                     velA: point.velocity,
                                     posB: pt,
                                     velB: edgeVelocity,
                                     distance: 0,
                                     springK: springCoefficient * strength,
                                     springD: springDampness * strength)
            
            point.applyForce(of: force)
            edgeHit.edgePoint1.applyForce(of: -force * (1 - edgeHit.edgeRatio))
            edgeHit.edgePoint2.applyForce(of: -force * edgeHit.edgeRatio)
        }
    }
}
