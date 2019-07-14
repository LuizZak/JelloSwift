//
//  GameViewController.swift
//  Sample macOS
//
//  Created by Luiz Fernando Silva on 12/07/19.
//  Copyright © 2019 Luiz Fernando Silva. All rights reserved.
//

import Cocoa
import MetalKit
import JelloSwift

// Our macOS specific view controller
class GameViewController: NSViewController {

    var renderer: Renderer!
    var mtkView: GameView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? GameView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        mtkView.device = defaultDevice
        mtkView.sampleCount = 8

        let newRenderer = Renderer(metalKitView: mtkView)

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        mtkView.onMouseDown = { point in
            newRenderer.demoScene.touchDown(at: Vector2(x: point.x, y: point.y))
        }
        mtkView.onMouseMoved = { point in
            newRenderer.demoScene.touchMoved(at: Vector2(x: point.x, y: point.y))
        }
        mtkView.onMouseUp = { point in
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
        
        mtkView.physicsTimeLabel.stringValue = String(format: "Physics update time: %0.2lfms (%0.0lffps) Avg time (last \(intervalCount) frames): %0.2lfms", timeMilliRounded, fps, avgMilliRounded)
    }
    
    func didUpdateRenderTimer(timeMilliRounded: TimeInterval, fps: TimeInterval) {
        guard let mtkView = self.view as? GameView else {
            print("View of Gameview controller is not an MTKView")
            return
        }
        
        mtkView.renderTimeLabel.stringValue = String(format: "Render time:              %0.2lfms (%0.0lffps)", timeMilliRounded, fps)
    }
}

class GameView: MTKView {
    let physicsTimeLabel = NSTextField()
    let renderTimeLabel = NSTextField()
    
    var onMouseDown: ((NSPoint) -> Void)?
    var onMouseMoved: ((NSPoint) -> Void)?
    var onMouseUp: ((NSPoint) -> Void)?
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        createTrackingArea()
        createLabels()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        createTrackingArea()
        createLabels()
    }
    
    func createTrackingArea() {
        // Add tracking
        let options: NSTrackingArea.Options = [.activeAlways, .inVisibleRect, .mouseMoved, .enabledDuringMouseDrag]
        let area = NSTrackingArea(rect: bounds, options:options, owner: self, userInfo: nil)
        
        self.addTrackingArea(area)
    }
    
    func createLabels() {
        physicsTimeLabel.backgroundColor = .clear
        physicsTimeLabel.textColor = .black
        physicsTimeLabel.isBezeled = false
        physicsTimeLabel.isBordered = false
        physicsTimeLabel.isEditable = false
        renderTimeLabel.backgroundColor = .clear
        renderTimeLabel.textColor = .black
        renderTimeLabel.isBezeled = false
        renderTimeLabel.isBordered = false
        renderTimeLabel.isEditable = false
        
        
        addSubview(physicsTimeLabel)
        addSubview(renderTimeLabel)
    }
    
    override func layout() {
        super.layout()
        
        physicsTimeLabel.frame = CGRect(x: 20, y: bounds.height - 20, width: bounds.width - 40, height: 20)
        renderTimeLabel.frame = CGRect(x: 20, y: bounds.height - 37, width: bounds.width - 40, height: 20)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        onMouseDown?(convert(event.locationInWindow, from: nil))
    }
    
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        
        onMouseMoved?(convert(event.locationInWindow, from: nil))
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        onMouseMoved?(convert(event.locationInWindow, from: nil))
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        
        onMouseUp?(convert(event.locationInWindow, from: nil))
    }
}
