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
    var pointMassA: Int = 0;
    var pointMassB: Int = 0;
    
    var springD: CGFloat = 0;
    var springK: CGFloat = 0;
    var damping: CGFloat = 0;
    
    override init()
    {
        super.init();
    }
    
    init(_ pmA: Int = 0, _ pmB: Int = 0, _ springD: CGFloat = 0, _ springK: CGFloat, _ damping: CGFloat)
    {
        self.pointMassA = pmA;
        self.pointMassB = pmB;
        self.springD = springD;
        self.springK = springK;
        self.damping = damping;
    }
}