//
//  InternalSpring.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Represents an internal spring inside a soft body object, and keeps points close together
class InternalSpring
{
    var pointMassA: PointMass;
    var pointMassB: PointMass;
    
    var distance: CGFloat = 0;
    var springK: CGFloat = 0;
    var springD: CGFloat = 0;
    
    init(_ pmA: PointMass, _ pmB: PointMass, _ distance: CGFloat = 0, _ springK: CGFloat, _ springD: CGFloat)
    {
        self.pointMassA = pmA;
        self.pointMassB = pmB;
        self.distance = distance;
        self.springK = springK;
        self.springD = springD;
    }
}