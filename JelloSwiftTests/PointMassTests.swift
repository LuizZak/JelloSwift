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
        
        p.integrate(1.0);
        
        XCTAssertEqual(p.velocity, Vector2(3, 6) / 0.2, "The velocity did not accumulate as expected!");
        XCTAssertEqual(p.force, Vector2.Zero, "After integrating a point mass, the force should reset to 0!");
        
        XCTAssertEqual(p.position, Vector2(3, 6) / 0.2,
            "The position of the point mass should be modified on the same integration the velocity is modified!");
    }
}