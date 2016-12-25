//
//  SpringComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

/// Represents a Spring component that can be added to a body to include spring-based physics in the body's point masses
public final class SpringComponent: BodyComponent
{
    /// Gets the count of springs on this spring component
    public var springCount: Int { return springs.count }
    
    /// The list of internal springs for the body
    fileprivate var springs: [InternalSpring] = []
    /// Whether the shape matching is on - turning on shape matching will make the soft body try to mantain its original
    /// shape as specified by its baseShape
    fileprivate var shapeMatchingOn = true
    
    /// The spring constant for the edges of the spring body
    fileprivate var edgeSpringK: CGFloat = 50
    /// The spring dampness for the edges of the spring body
    fileprivate var edgeSpringDamp: CGFloat = 2
    
    /// The spring constant for the shape matching of the body - ignored if shape matching is off
    fileprivate var shapeSpringK: CGFloat = 200
    /// The spring dampness for the shape matching of the body - ignored if the shape matching is off
    fileprivate var shapeSpringDamp: CGFloat = 10
    
    override public func prepare(_ body: Body)
    {
        clearAllSprings(body)
    }
    
    /// Adds an internal spring to this body
    @discardableResult
    public func addInternalSpring(_ body: Body, pointA: Int, pointB: Int, springK: CGFloat, damping: CGFloat, dist: CGFloat? = nil) -> InternalSpring
    {
        let pointA = body.pointMasses[pointA]
        let pointB = body.pointMasses[pointB]
        
        let dist = dist ?? pointA.position.distanceTo(pointB.position)
        
        let s = InternalSpring(pointA, pointB, dist, springK, damping)
        
        springs += s
        
        return s
    }
    
    /// Clears all the internal springs from the body.
    /// The original edge springs are mantained
    public func clearAllSprings(_ body: Body)
    {
        springs = []
        
        _buildDefaultSprings(body)
    }
    
    /// Builds the default edge internal springs for this spring body
    public func _buildDefaultSprings(_ body: Body)
    {
        for i in 0..<body.pointMasses.count
        {
            addInternalSpring(body, pointA: i, pointB: (i + 1) % body.pointMasses.count, springK: edgeSpringK, damping: edgeSpringDamp)
        }
    }
    
    /// Sets the shape-matching spring constants
    public func setShapeMatchingConstants(_ springK: CGFloat, _ damping: CGFloat)
    {
        shapeSpringK = springK
        shapeSpringDamp = damping
    }
    
    /// Changes the spring constants for the springs around the shape itself (edge springs)
    public func setEdgeSpringConstants(_ body: Body, edgeSpringK: CGFloat, _ edgeSpringDamp: CGFloat)
    {
        // we know that the first n springs in the list are the edge springs.
        for i in 0..<body.pointMasses.count
        {
            springs[i].springK = edgeSpringK
            springs[i].springD = edgeSpringDamp
        }
    }
    
    /// Sets the spring constant for the given spring index.
    /// The spring index starts from pointMasses.count and onwards, so the first spring
    /// will not be the first edge spring.
    public func setSpringConstants(_ body: Body, springID: Int, _ springK: CGFloat, _ springDamp: CGFloat)
    {
        // index is for all internal springs, AFTER the default internal springs.
        let index = body.pointMasses.count + springID
        
        springs[index].springK = springK
        springs[index].springD = springDamp
    }
    
    /// Gets the spring constant of a spring at the specified index.
    /// This ignores the default edge springs, so the index is always + body.pointMasses.count
    public func getSpringK(_ body: Body, springID: Int) -> CGFloat
    {
        return springs[body.pointMasses.count + springID].springK
    }
    
    /// Gets the spring dampness of a spring at the specified index
    /// This ignores the default edge springs, so the index is always + body.pointMasses.count
    public func getSpringD(_ body: Body, springID: Int) -> CGFloat
    {
        return springs[body.pointMasses.count + springID].springD
    }
    
    override public func accumulateInternalForces(_ body: Body)
    {
        super.accumulateInternalForces(body)
        
        for s in springs
        {
            let p1 = s.pointMassA
            let p2 = s.pointMassB
            
            let force = calculateSpringForce(p1.position, velA: p1.velocity, posB: p2.position, velB: p2.velocity, distance: s.distance, springK: s.springK, springD: s.springD)
            
            p1.force += force
            p2.force -= force
        }
        
        if(!shapeMatchingOn || shapeSpringK == 0)
        {
            return
        }
        
        body.baseShape.transformVertices(&body.globalShape, worldPos: body.derivedPos, angleInRadians: body.derivedAngle, localScale: body.scale)
        
        for (i, p) in body.pointMasses.enumerated()
        {
            let force: Vector2
            
            if(!body.isKinematic)
            {
                force = calculateSpringForce(p.position, velA: p.velocity, posB: body.globalShape[i], velB: p.velocity, distance: 0.0, springK: shapeSpringK, springD: shapeSpringDamp)
            }
            else
            {
                force = calculateSpringForce(p.position, velA: p.velocity, posB: body.globalShape[i], velB: Vector2.zero, distance: 0.0, springK: shapeSpringK, springD: shapeSpringDamp)
            }
            
            p.force += force
        }
    }
}

/// Creator for the Spring component
open class SpringComponentCreator : BodyComponentCreator
{
    /// Whether the shape matching is on - turning on shape matching will make the soft body try to mantain its original
    /// shape as specified by its baseShape
    open var shapeMatchingOn = true
    
    /// The spring constant for the edges of the spring body
    open var edgeSpringK: CGFloat = 50
    /// The spring dampness for the edges of the spring body
    open var edgeSpringDamp: CGFloat = 2
    
    /// The spring constant for the shape matching of the body - ignored if shape matching is off
    open var shapeSpringK: CGFloat = 200
    /// The spring dampness for the shape matching of the body - ignored if the shape matching is off
    open var shapeSpringDamp: CGFloat = 10
    
    /// An array of inner springs for a body
    open var innerSprings: [SpringComponentInnerSpring] = []
    
    public required init(shapeMatchingOn: Bool = true, edgeSpringK: CGFloat = 50, edgeSpringDamp: CGFloat = 2, shapeSpringK: CGFloat = 200, shapeSpringDamp: CGFloat = 10, innerSprings: [SpringComponentInnerSpring] = [])
    {
        self.shapeMatchingOn = shapeMatchingOn
        
        self.edgeSpringK = edgeSpringK
        self.edgeSpringDamp = edgeSpringDamp
        
        self.shapeSpringK = shapeSpringK
        self.shapeSpringDamp = shapeSpringDamp
        
        self.innerSprings = innerSprings
        
        super.init()
        
        bodyComponentClass = SpringComponent.self
    }
    
    open override func prepareBodyAfterComponent(_ body: Body)
    {
        guard let comp = body.getComponentType(SpringComponent.self) else {
            return
        }
        
        comp.shapeMatchingOn = shapeMatchingOn
        
        comp.setEdgeSpringConstants(body, edgeSpringK: edgeSpringK, edgeSpringDamp)
        comp.setShapeMatchingConstants(shapeSpringK, shapeSpringDamp)
        
        innerSprings.forEach { element in
            comp.addInternalSpring(body, pointA: element.indexA, pointB: element.indexB, springK: element.springK, damping: element.springD, dist: element.dist)
        }
    }
}

/// Specifies a template for an inner spring
public struct SpringComponentInnerSpring
{
    public var indexA = 0
    public var indexB = 0
    
    public var springK: CGFloat = 0
    public var springD: CGFloat = 0
    
    public var dist: CGFloat = 0
    
    public init(a: Int, b: Int, springK: CGFloat, springD: CGFloat, dist: CGFloat = -1)
    {
        indexA = a
        indexB = b
        
        self.springK = springK
        self.springD = springD
        
        self.dist = dist
    }
}
