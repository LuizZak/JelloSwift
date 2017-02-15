//
//  InternalSpring.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 07/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import CoreGraphics

// Represents an internal spring inside a soft body object, and keeps points close together
public struct InternalSpring {
    
    public let pointMassA: PointMass
    public let pointMassB: PointMass
    
    public var distance: CGFloat = 0
    public var coefficient: CGFloat = 0
    public var damping: CGFloat = 0
    
    public init(_ pmA: PointMass, _ pmB: PointMass, _ distance: CGFloat = 0, _ springK: CGFloat, _ springD: CGFloat) {
        pointMassA = pmA
        pointMassB = pmB
        self.distance = distance
        coefficient = springK
        damping = springD
    }
}
