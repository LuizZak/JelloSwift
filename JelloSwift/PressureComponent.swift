//
//  PressureComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Represents a Pressure component that can be added to a body to include gas pressure as an internal force
class PressureComponent: BodyComponent
{
    // PRIVATE VARIABLES
    final var volume: CGFloat = 0;
    final var gasAmmount: CGFloat = 0;
    final var normalList: [Vector2] = [];
    final var edgeLengthList: [CGFloat] = [];
    
    override func prepare(body: Body)
    {
        normalList = [Vector2](count: body.pointMasses.count, repeatedValue: Vector2());
        edgeLengthList = [CGFloat](count: body.pointMasses.count, repeatedValue: 0);
    }
    
    override func accumulateInternalForces()
    {
        super.accumulateInternalForces();
        // internal forces based on pressure equations.  we need 2 loops to do this.  one to find the overall volume of the
        // body, and 1 to apply forces. we will need the normals for the edges in both loops, so we will cache them and remember them.
        volume = 0;
        
        var edge1NX: CGFloat, edge1NY: CGFloat, edge2NX: CGFloat, edge2NY: CGFloat, t: CGFloat;
        var normX: CGFloat, normY: CGFloat;
        
        let c = body.pointMasses.count;
        var prev = c - 1;
        
        for var i = 0; i < c; i++
        {
            let curPoint:PointMass = body.pointMasses[i];
            
            let next: Int = (i + 1) % (c);
            
            // currently we are talking about the edge from i --> j.
            // first calculate the volume of the body, and cache normals as we go.
            let edge1N = (curPoint.position - body.pointMasses[prev].position).perpendicular();
            let edge2N = (body.pointMasses[next].position - curPoint.position).perpendicular();
            
            // cache normal and edge length
            normalList[i] = (edge1N + edge2N).normalized();
            edgeLengthList[i] = edge2N.magnitude();
            
            prev = i;
        }
        
        volume = max(0.5, polygonArea(body.pointMasses));
        
        // now loop through, adding forces!
        let invVolume: CGFloat = 1 / volume;
        
        for var i = 0; i < c; i++
        {
            let j: Int = (i + 1) % c;
            let pressureV: CGFloat = (invVolume * edgeLengthList[i] * (gasAmmount));
            
            body.pointMasses[i].force += normalList[i] * pressureV;
            body.pointMasses[j].force += normalList[j] * pressureV;
        }
    }
}

// Creator for the Spring component
class PressureComponentCreator : BodyComponentCreator
{
    var gasAmmount: CGFloat;
    
    required init(gasAmmount: CGFloat = 0)
    {
        self.gasAmmount = gasAmmount;
        
        super.init();
        
        self.bodyComponentClass = PressureComponent.self;
    }
    
    override func prepareBodyAfterComponent(body: Body)
    {
        if let comp = body.getComponentType(PressureComponent)
        {
            comp.gasAmmount = self.gasAmmount;
        }
    }
}