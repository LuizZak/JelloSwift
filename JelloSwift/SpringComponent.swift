//
//  SpringComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Represents a Spring component that can be added to a body to include spring-based physics in the body's point masses
class SpringComponent: BodyComponent
{
    var springs:[InternalSpring] = [];
    var shapeMatchingOn = true;
    
    var edgeSpringK: CGFloat = 50;
    var edgeSpringDamp: CGFloat = 2;
    
    var shapeSpringK: CGFloat = 200;
    var shapeSpringDamp: CGFloat = 10;
    
    override func prepare(body: Body)
    {
        self._buildDefaultSprings();
    }
    
    // Adds an internal spring to this body
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
    
    // Clears all the internal springs from the body
    func clearAllSprings()
    {
        springs = [];
        
        _buildDefaultSprings();
    }
    
    // Builds the default edge internal springs for this spring body
    func _buildDefaultSprings()
    {
        for i in 0..<body.pointMasses.count
        {
            addInternalSpring(i, pointB: (i + 1) % body.pointMasses.count, springK: edgeSpringK, damping: edgeSpringDamp);
        }
    }
    
    // Sets the shape-matching spring constants
    func setShapeMatchingConstants(springK: CGFloat, _ damping: CGFloat)
    {
        shapeSpringK = springK;
        shapeSpringDamp = damping;
    }
    
    // Changes the spring constants for the springs around the shape itself (edge springs)
    func setEdgeSpringConstants(edgeSpringK: CGFloat, _ edgeSpringDamp: CGFloat)
    {
        // we know that the first n springs in the list are the edge springs.
        for i in 0..<body.pointMasses.count
        {
            springs[i].springK = edgeSpringK;
            springs[i].damping = edgeSpringDamp;
        }
    }
    
    // Sets the spring constant for the given spring index.
    // The spring index starts from pointMasses.count and onwards, so the first spring
    // will not be the first edge spring.
    func setSpringConstants(springID: Int, _ springK: CGFloat, _ springDamp: CGFloat)
    {
        // index is for all internal springs, AFTER the default internal springs.
        var index = body.pointMasses.count + springID;
        
        springs[index].springK = springK;
        springs[index].damping = springDamp;
    }
    
    func getSpringK(springID: Int) -> CGFloat
    {
        return springs[body.pointMasses.count + springID].springK;
    }
    
    func getSpringD(springID: Int) -> CGFloat
    {
        return springs[body.pointMasses.count + springID].springD;
    }
    
    override func accumulateInternalForces()
    {
        super.accumulateInternalForces();
        
        var force = Vector2();
        
        for s in springs
        {
            let p1 = body.pointMasses[s.pointMassA];
            let p2 = body.pointMasses[s.pointMassB];
            
            var force = calculateSpringForce(p1.position, p1.velocity, p2.position, p2.velocity, s.springD, s.springK, s.damping);
            
            p1.force += force;
            p2.force -= force;
        }
        
        if(shapeMatchingOn)
        {
            body.globalShape = body.baseShape.transformVertices(body.derivedPos, angleInRadians: body.derivedAngle, localScale: body.scale);
            
            for i in 0..<body.pointMasses.count
            {
                var p = body.pointMasses[i];
                
                if(shapeSpringK > 0)
                {
                    var force = Vector2();
                    
                    if(!body.isKinematic)
                    {
                        force = calculateSpringForce(p.position, p.velocity, body.globalShape[i], p.velocity, 0.0, shapeSpringK, shapeSpringDamp);
                    }
                    else
                    {
                        force = calculateSpringForce(p.position, p.velocity, body.globalShape[i], Vector2(), 0.0, shapeSpringK, shapeSpringDamp);
                    }
                    
                    p.force += force;
                }
            }
        }
    }
}

// Creator for the Spring component
class SpringComponentCreator : BodyComponentCreator
{
    var shapeMatchingOn = true;
    
    var edgeSpringK: CGFloat = 50;
    var edgeSpringDamp: CGFloat = 2;
    
    var shapeSpringK: CGFloat = 200;
    var shapeSpringDamp: CGFloat = 10;
    
    required init(shapeMatchingOn: Bool = true, edgeSpringK: CGFloat = 50, edgeSpringDamp: CGFloat = 2, shapeSpringK: CGFloat = 200, shapeSpringDamp: CGFloat = 10)
    {
        self.shapeMatchingOn = shapeMatchingOn;
        
        self.edgeSpringK = edgeSpringK;
        self.edgeSpringDamp = edgeSpringDamp;
        
        self.shapeSpringK = shapeSpringK;
        self.shapeSpringDamp = shapeSpringDamp;
        
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
        }
    }
}