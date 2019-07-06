//
//  BendConstraintComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 01/05/19.
//

/// Represents an internal constraint that tries to straighten out adjacent
/// point masses into a straight line.
public final class BendConstraintComponent: BodyComponent {
    
    /// The affected point masses to straighten out. This array should contain
    /// the central particles whose neighboring particles will also be affected,
    /// as a result of the algorithm's nature of affecting three particles at any
    /// given point.
    ///
    /// Applies to all point masses, if `nil`.
    public var pointMasses: [Int]?
    
    /// The stiffness coefficient for the constraint.
    public var stiffness: JFloat = 0.04
    
    public init() {
        
    }
    
    public func accumulateInternalForces(in body: Body, relaxing: Bool) {
        for index in pointMasses ?? Array(0..<body.pointMasses.count) {
            let prev = body.pointMasses[(index + 1) % body.pointMasses.count]
            let point = body.pointMasses[index]
            let next = body.pointMasses[index == 0 ? body.pointMasses.count - 1 : index - 1]
            
            let baseLength = prev.position.distance(to: next.position)
            
            if baseLength == 0 {
                continue
            }
            
            // Base of triangle from prev to point to next
            let base = (next.position - prev.position).normalized()
            let adotb = ((prev.position - point.position) • base)
            
            // Projected position of particle towards triangle base
            let actualPoint = base * adotb
            let basePosition = prev.position - actualPoint
            let ratio = adotb / baseLength
            let offset = basePosition - point.position
            
            prev.applyForce(of: -offset * stiffness)
            point.applyForce(of: offset * stiffness)
            next.applyForce(of: -offset * stiffness)
        }
    }
}

/// Creator for the Bend Constraint component
public struct BendConstraintComponentCreator: BodyComponentCreator, Codable {
    
    public static var bodyComponentClass: BodyComponent.Type = BendConstraintComponent.self
    
    /// The affected point masses to straighten out. This array should contain
    /// the central particles whose neighboring particles will also be affected,
    /// as a result of the algorithm's nature of affecting three particles at any
    /// given point.
    ///
    /// Applies to all point masses, if `nil`.
    public var pointMasses: [Int]?
    
    /// The stiffness coefficient for the constraint.
    public var stiffness: JFloat
    
    /// Creates a new instance of the `BendConstraintComponentCreator` struct.
    ///
    /// - Parameters:
    ///   - pointMasses: The point masses to apply the bend constraint to.
    /// Leave `nil` to apply to all point masses of a body.
    ///   - stiffness: The stiffness coefficient for the constraint.
    public init(pointMasses: [Int]? = nil, stiffness: JFloat = 0.04) {
        self.pointMasses = pointMasses
        self.stiffness = stiffness
    }
    
    public func prepareBodyAfterComponent(_ body: Body, component: BodyComponent) {
        guard let component = component as? BendConstraintComponent else {
            return
        }
        
        component.pointMasses = pointMasses
        component.stiffness = stiffness
    }
}
