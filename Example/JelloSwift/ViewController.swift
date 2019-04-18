//
//  ViewController.swift
//  JelloSwift
//
//  Created by LuizZak on 02/14/2017.
//  Copyright (c) 2017 LuizZak. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var btnRenderingMode: UIButton!
    
    var demo: DemoView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(white: 0.7, alpha: 1)
        
        btnRenderingMode.layer.cornerRadius = 5
        btnRenderingMode.layer.borderWidth = 2
        btnRenderingMode.layer.borderColor = UIColor(white: 0, alpha: 0.5).cgColor
        btnRenderingMode.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        btnRenderingMode.backgroundColor = UIColor(white: 0.7, alpha: 1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Must be created on viewDidAppear to ensure view controller is sized
        // correctly by now
        demo = DemoView(frame: view.frame)
        view.insertSubview(demo, at: 0)
        
        view.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[demo]|",
                                           options: [],
                                           metrics: nil,
                                           views: ["demo": demo as Any])
        )
        
        view.addConstraints(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[demo]|",
                                           options: [],
                                           metrics: nil,
                                           views: ["demo": demo as Any])
        )
    }
    
    @IBAction func didTapRenderingMode(_ sender: UIButton) {
        demo.useDetailedRender = !demo.useDetailedRender
        
        if !demo.useDetailedRender {
            btnRenderingMode.setImage(UIImage(named: "img_detailed"), for: .normal)
        } else {
            btnRenderingMode.setImage(UIImage(named: "img_simple"), for: .normal)
        }
    }
}
