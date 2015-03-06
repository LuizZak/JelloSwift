//
//  InternalSpring.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit

// Represents an internal spring inside a soft body object, and keeps points close together
class InternalSpring: NSObject
{
    var pointMassA: PointMass;
    var pointMassB: PointMass;
    
    var springD: CGFloat = 0;
    var springK: CGFloat = 0;
    var damping: CGFloat = 0;
    
    init(_ pmA: PointMass, _ pmB: PointMass, _ springD: CGFloat = 0, _ springK: CGFloat, _ damping: CGFloat)
    {
        self.pointMassA = pmA;
        self.pointMassB = pmB;
        self.springD = springD;
        self.springK = springK;
        self.damping = damping;
    }
}