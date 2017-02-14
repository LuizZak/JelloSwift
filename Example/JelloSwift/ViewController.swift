//
//  ViewController.swift
//  JelloSwift
//
//  Created by LuizZak on 02/14/2017.
//  Copyright (c) 2017 LuizZak. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.backgroundColor = UIColor(white: 0.7, alpha: 1)
        
        let demo = DemoView(frame: view.frame)
        view.addSubview(demo)
    }
}
