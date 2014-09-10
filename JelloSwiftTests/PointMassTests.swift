//
//  PointMassTests.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 10/08/14.
//  Copyright (c) 2014 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import XCTest

class PointMassTests: XCTestCase
{
    func testExample()
    {
        var p = PointMass(mass: 0.2, position: Vector2(0, 0));
        p.force += Vector2(1, 2);
        p.force += Vector2(1, 2);
        p.force += Vector2(1, 2);
        
        p.integrate(1.0 / 200);
        
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
}