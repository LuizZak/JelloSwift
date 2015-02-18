//
//  CustomView.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 18/02/15.
//  Copyright (c) 2015 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import SpriteKit

class CustomView: SKView
{
    var polyDrawer:PolyDrawer?;
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        super.drawRect(rect);
        
        // Drawing code
        if let drawer = polyDrawer
        {
            drawer.renderOnContext(UIGraphicsGetCurrentContext());
        }
    }
}