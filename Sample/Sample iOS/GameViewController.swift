//
//  GameViewController.swift
//  Sample iOS
//
//  Created by Luiz Fernando Silva on 12/07/19.
//  Copyright © 2019 Luiz Fernando Silva. All rights reserved.
//

import UIKit
import MetalKit
import JelloSwift

// Our iOS specific view controller
class GameViewController: UIViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? GameView else {
            print("View of Gameview controller is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }

        mtkView.device = defaultDevice
        mtkView.backgroundColor = UIColor.black

        let newRenderer = Renderer(metalKitView: mtkView)

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        mtkView.onTouchBegan = { point in
            newRenderer.demoScene.touchDown(at: Vector2(x: point.x, y: point.y))
        }
        mtkView.onTouchMoved = { point in
            newRenderer.demoScene.touchMoved(at: Vector2(x: point.x, y: point.y))
        }
        mtkView.onTouchEnded = { point in
            newRenderer.demoScene.touchEnded(at: Vector2(x: point.x, y: point.y))
        }
        renderer.demoScene.delegate = self
    }
}

extension GameViewController: DemoSceneDelegate {
    func didUpdatePhysicsTimer(intervalCount: Int, timeMilliRounded: TimeInterval, fps: TimeInterval, avgMilliRounded: TimeInterval) {
        guard let mtkView = self.view as? GameView else {
            print("View of Gameview controller is not an MTKView")
            return
        }
        
        mtkView.physicsTimeLabel.text = String(format: "Physics update time: %0.2lfms (%0.0lffps) Avg time (last \(intervalCount) frames): %0.2lfms", timeMilliRounded, fps, avgMilliRounded)
    }
    
    func didUpdateRenderTimer(timeMilliRounded: TimeInterval, fps: TimeInterval) {
        guard let mtkView = self.view as? GameView else {
            print("View of Gameview controller is not an MTKView")
            return
        }
        
        mtkView.renderTimeLabel.text = String(format: "Render time:              %0.2lfms (%0.0lffps)", timeMilliRounded, fps)
    }
}

class GameView: MTKView {
    let physicsTimeLabel = UILabel()
    let renderTimeLabel = UILabel()
    
    var onTouchBegan: ((CGPoint) -> Void)?
    var onTouchMoved: ((CGPoint) -> Void)?
    var onTouchEnded: ((CGPoint) -> Void)?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        addSubview(physicsTimeLabel)
        addSubview(renderTimeLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        physicsTimeLabel.frame = CGRect(x: 20, y: 20, width: bounds.width - 40, height: 20)
        renderTimeLabel.frame = CGRect(x: 20, y: 37, width: bounds.width - 40, height: 20)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: self)
        onTouchBegan?(invertingYAxis(location))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: self)
        onTouchMoved?(invertingYAxis(location))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: self)
        onTouchEnded?(invertingYAxis(location))
    }
    
    func invertingYAxis(_ point: CGPoint) -> CGPoint {
        var point = point
        point.y = bounds.height - point.y
        return point
    }
}
