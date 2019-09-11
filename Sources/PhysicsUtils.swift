//
//  PhysicsUtils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 13/09/17.
//

/// Calculates a spring force, given position, velocity, spring constant, and
/// damping factor
@inlinable
public func calculateSpringForce(posA: Vector2, velA: Vector2,
                                 posB: Vector2, velB: Vector2,
                                 distance: JFloat,
                                 springK: JFloat,
                                 springD: JFloat) -> Vector2 {
    
    var dist = posA.distance(to: posB)
    
    if (dist <= 0.0000005) {
        return .zero
    }
    
    let BtoA = (posA - posB) / dist
    
    dist = distance - dist
    
    let relVel = velA - velB
    let totalRelVel = relVel • BtoA
    
    return BtoA * ((dist * springK) - (totalRelVel * springD))
}

/// Calculates a spring force, given position, velocity, spring constant, and
/// damping factor.
///
/// The target distance is given as a square of the actual target distance to
/// allow skipping square rooting the distance from `postA` to `posB`
@inlinable
public func calculateSpringForce(posA: Vector2, velA: Vector2,
                                 posB: Vector2, velB: Vector2,
                                 distanceSquared: JFloat,
                                 springK: JFloat,
                                 springD: JFloat) -> Vector2 {
    
    var dist = posA.distanceSquared(to: posB)
    
    if (dist <= 0.0000005) {
        return .zero
    }
    
    let BtoA = (posA - posB) / dist
    
    dist = distanceSquared - dist
    
    let relVel = velA - velB
    let totalRelVel = relVel • BtoA
    
    return BtoA * ((dist * springK) - (totalRelVel * springD))
}

/// Calculates a new resting distance based on provided plasticity parameters.
/// The resulting resting distance is returned by the function.
///
/// - Parameters:
///   - distance: The current distance of the spring
///   - restDistance: The resting distance for the spring
///   - initialRestDistance: The initial resting distance of the spring, ignoring
/// any plasticity changes
///   - plasticity: The plasticity coefficients
/// - Returns: The new rest distance to the spring, after plasticity is applied.
@inlinable
public func calculatePlasticity(distance: JFloat,
                                restDistance: RestDistance,
                                initialRestDistance: RestDistance,
                                plasticity: SpringPlasticity) -> RestDistance
{
    if restDistance.inRange(value: distance) { // Exact distance - no plasticity changes
        return restDistance
    }
    
    var outDistance = restDistance
    
    // Based on source code found at:
    // https://github.com/justincouch/cinderFluid/blob/a07cc282d36c37d1bd782a36d6ffaf4c801334eb/Fluid/xcode/Spring.cpp#L46
    //
    if distance > restDistance.maximumDistance {
        let d = plasticity.yieldRatio * restDistance.maximumDistance
        
        if distance > restDistance.maximumDistance + d {
            outDistance.maximumDistance += plasticity.rate * (distance - outDistance.maximumDistance - d)
            
            if outDistance.maximumDistance > initialRestDistance.maximumDistance * plasticity.limit {
                outDistance.maximumDistance = initialRestDistance.maximumDistance * plasticity.limit
            }
        }
        
    } else if distance < restDistance.minimumDistance {
        let d = plasticity.yieldRatio * restDistance.minimumDistance
        
        if distance < restDistance.minimumDistance - d {
            outDistance.minimumDistance -= plasticity.rate * (outDistance.minimumDistance - d - distance)
            
            if outDistance.minimumDistance < initialRestDistance.minimumDistance / plasticity.limit {
                outDistance.minimumDistance = initialRestDistance.minimumDistance / plasticity.limit
            }
        }
    }
    
    return outDistance
}
