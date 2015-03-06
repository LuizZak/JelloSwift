//
//  SpringComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

/// Represents a Spring component that can be added to a body to include spring-based physics in the body's point masses
class SpringComponent: BodyComponent
{
    /// Gets the count of springs on this spring component
    var springCount: Int { return springs.count; }
    
    /// The list of internal springs for the body
    private var springs:[InternalSpring] = [];
    /// Whether the shape matching is on - turning on shape matching will make the soft body try to mantain its original
    /// shape as specified by its baseShape
    private var shapeMatchingOn = true;
    
    /// The spring constant for the edges of the spring body
    private var edgeSpringK: CGFloat = 50;
    /// The spring dampness for the edges of the spring body
    private var edgeSpringDamp: CGFloat = 2;
    
    /// The spring constant for the shape matching of the body - ignored if shape matching is off
    private var shapeSpringK: CGFloat = 200;
    /// The spring dampness for the shape matching of the body - ignored if the shape matching is off
    private var shapeSpringDamp: CGFloat = 10;
    
    override func prepare(body: Body)
    {
        self._buildDefaultSprings();
    }
    
    /// Adds an internal spring to this body
    func addInternalSpring(pointA: Int, pointB: Int, springK: CGFloat, damping: CGFloat, dist: CGFloat = -1) -> InternalSpring
    {
        var d = dist;
        
        if(d < 0)
        {
            d = body.pointMasses[pointA].position.distanceTo(body.pointMasses[pointB].position);
        }
        
        var s = InternalSpring(pointA, pointB, d, springK, damping);
        
        springs += s;
        
        return s;
    }
    
    /// Clears all the internal springs from the body.
    /// The original edge springs are mantained
    func clearAllSprings()
    {
        springs = [];
        
        _buildDefaultSprings();
    }
    
    /// Builds the default edge internal springs for this spring body
    func _buildDefaultSprings()
    {
        for i in 0..<body.pointMasses.count
        {
            addInternalSpring(i, pointB: (i + 1) % body.pointMasses.count, springK: edgeSpringK, damping: edgeSpringDamp);
        }
    }
    
    /// Sets the shape-matching spring constants
    func setShapeMatchingConstants(springK: CGFloat, _ damping: CGFloat)
    {
        shapeSpringK = springK;
        shapeSpringDamp = damping;
    }
    
    /// Changes the spring constants for the springs around the shape itself (edge springs)
    func setEdgeSpringConstants(edgeSpringK: CGFloat, _ edgeSpringDamp: CGFloat)
    {
        // we know that the first n springs in the list are the edge springs.
        for i in 0..<body.pointMasses.count
        {
            springs[i].springK = edgeSpringK;
            springs[i].damping = edgeSpringDamp;
        }
    }
    
    /// Sets the spring constant for the given spring index.
    /// The spring index starts from pointMasses.count and onwards, so the first spring
    /// will not be the first edge spring.
    func setSpringConstants(springID: Int, _ springK: CGFloat, _ springDamp: CGFloat)
    {
        // index is for all internal springs, AFTER the default internal springs.
        var index = body.pointMasses.count + springID;
        
        springs[index].springK = springK;
        springs[index].damping = springDamp;
    }
    
    /// Gets the spring constant of a spring at the specified index.
    /// This ignores the default edge springs, so the index is always + body.pointMasses.count
    func getSpringK(springID: Int) -> CGFloat
    {
        return springs[body.pointMasses.count + springID].springK;
    }
    
    /// Gets the spring dampness of a spring at the specified index
    /// This ignores the default edge springs, so the index is always + body.pointMasses.count
    func getSpringD(springID: Int) -> CGFloat
    {
        return springs[body.pointMasses.count + springID].springD;
    }
    
    override func accumulateInternalForces()
    {
        super.accumulateInternalForces();
        
        var force = Vector2();
        
        for var i = 0; i < springs.count; i++
        {
            let s = springs[i];
            
            let p1 = body.pointMasses[s.pointMassA];
            let p2 = body.pointMasses[s.pointMassB];
            
            let force = calculateSpringForce(p1.position, p1.velocity, p2.position, p2.velocity, s.springD, s.springK, s.damping);
            
            p1.force += force;
            p2.force -= force;
        }
        
        if(shapeMatchingOn && shapeSpringK > 0)
        {
            body.baseShape.transformVertices(&body.globalShape, worldPos: body.derivedPos, angleInRadians: body.derivedAngle, localScale: body.scale);
            
            let c = body.pointMasses.count;
            for var i = 0; i < c; i++
            {
                let p = body.pointMasses[i];
                
                let force:Vector2;
                
                if(!body.isKinematic)
                {
                    force = calculateSpringForce(p.position, p.velocity, body.globalShape[i], p.velocity, 0.0, shapeSpringK, shapeSpringDamp);
                }
                else
                {
                    force = calculateSpringForce(p.position, p.velocity, body.globalShape[i], Vector2.Zero, 0.0, shapeSpringK, shapeSpringDamp);
                }
                
                p.force += force;
            }
        }
    }
}

/// Creator for the Spring component
class SpringComponentCreator : BodyComponentCreator
{
    /// Whether the shape matching is on - turning on shape matching will make the soft body try to mantain its original
    /// shape as specified by its baseShape
    var shapeMatchingOn = true;
    
    /// The spring constant for the edges of the spring body
    var edgeSpringK: CGFloat = 50;
    /// The spring dampness for the edges of the spring body
    var edgeSpringDamp: CGFloat = 2;
    
    /// The spring constant for the shape matching of the body - ignored if shape matching is off
    var shapeSpringK: CGFloat = 200;
    /// The spring dampness for the shape matching of the body - ignored if the shape matching is off
    var shapeSpringDamp: CGFloat = 10;
    
    /// An array of inner springs for a body
    var innerSprings: [SpringComponentInnerSpring] = [];
    
    required init(shapeMatchingOn: Bool = true, edgeSpringK: CGFloat = 50, edgeSpringDamp: CGFloat = 2, shapeSpringK: CGFloat = 200, shapeSpringDamp: CGFloat = 10, innerSprings: [SpringComponentInnerSpring] = [])
    {
        self.shapeMatchingOn = shapeMatchingOn;
        
        self.edgeSpringK = edgeSpringK;
        self.edgeSpringDamp = edgeSpringDamp;
        
        self.shapeSpringK = shapeSpringK;
        self.shapeSpringDamp = shapeSpringDamp;
        
        self.innerSprings = innerSprings;
        
        super.init();
        
        self.bodyComponentClass = SpringComponent.self;
    }
    
    override func prepareBodyAfterComponent(body: Body)
    {
        if let comp = body.getComponentType(SpringComponent)
        {
            comp.shapeMatchingOn = self.shapeMatchingOn;
            
            comp.setEdgeSpringConstants(edgeSpringK, edgeSpringDamp);
            comp.setShapeMatchingConstants(shapeSpringK, shapeSpringDamp)
            
            innerSprings.forEach({ (element) -> Void in
                comp.addInternalSpring(element.indexA, pointB: element.indexB, springK: element.springK, damping: element.springD, dist: element.dist);
            });
        }
    }
}

/// Specifies a template for an inner spring
struct SpringComponentInnerSpring
{
    var indexA: Int = 0;
    var indexB: Int = 0;
    
    var springK: CGFloat = 0;
    var springD: CGFloat = 0;
    
    var dist: CGFloat = 0;
    
    init(a: Int, b: Int, springK: CGFloat, springD: CGFloat, dist: CGFloat = -1)
    {
        indexA = a;
        indexB = b;
        
        self.springK = springK;
        self.springD = springD;
        
        self.dist = dist;
    }
}