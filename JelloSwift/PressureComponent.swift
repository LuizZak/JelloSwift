//
//  PressureComponent.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 16/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Represents a Pressure component that can be added to a body to include gas pressure as an internal force
class PressureComponent: BodyComponent
{
    // PRIVATE VARIABLES
    var volume: CGFloat = 0;
    var gasAmmount: CGFloat = 0;
    var normalList: [Vector2] = [];
    var edgeLengthList: [CGFloat] = [];
    
    override func prepare(body: Body)
    {
        for p in body.pointMasses
        {
            normalList += Vector2();
            edgeLengthList += 0;
        }
    }
    
    override func accumulateInternalForces()
    {
        super.accumulateInternalForces();
        // internal forces based on pressure equations.  we need 2 loops to do this.  one to find the overall volume of the
        // body, and 1 to apply forces. we will need the normals for the edges in both loops, so we will cache them and remember them.
        volume = 0;
        
        var edge1NX: CGFloat, edge1NY: CGFloat, edge2NX: CGFloat, edge2NY: CGFloat, t: CGFloat;
        var normX: CGFloat, normY: CGFloat;
        
        var c = body.pointMasses.count;
        for i in 0..<c
        {
            var curPoint:PointMass = body.pointMasses[i];
            
            var prev: Int = (i > 0) ? i - 1 : c - 1;
            var next: Int = (i + 1) % (c);
            
            // currently we are talking about the edge from i --> j.
            // first calculate the volume of the body, and cache normals as we go.
            var edge1N = (curPoint.position - body.pointMasses[prev].position).perpendicular();
            var edge2N = (body.pointMasses[next].position - curPoint.position).perpendicular();
            
            // cache normal and edge length
            normalList[i] = (edge1N + edge2N).normalized();
            edgeLengthList[i] = edge2N.magnitude();
        }
        
        volume = polygonArea(body.pointMasses);
        
        // now loop through, adding forces!
        var invVolume: CGFloat;
        
        if(volume < 0.5)
        {
            invVolume = 1 / 0.5;
        }
        else
        {
            invVolume = 1 / volume;
        }
        
        //var pm_count:int = mPointMasses.length;
        for i in 0..<body.pointMasses.count
        {
            var j: Int = (i + 1) % body.pointMasses.count;
            var pressureV: CGFloat = (invVolume * edgeLengthList[i] * (gasAmmount));
            
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