//
//  Utils.swift
//  JelloSwift
//
//  Created by Luiz Fernando Silva on 14/02/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation

#if os(macOS)
import Cocoa
typealias Color = NSColor
#elseif os(iOS)
import UIKit
typealias Color = UIColor
#endif

class Stopwatch {
    var startTime: CFAbsoluteTime
    var endTime: CFAbsoluteTime?
    
    init(startTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()) {
        self.startTime = startTime
    }
    
    func start() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()
        
        return duration
    }
    
    static func startNew() -> Stopwatch {
        return Stopwatch(startTime: CFAbsoluteTimeGetCurrent())
    }
    
    func reset() {
        start()
    }
    
    var duration: CFAbsoluteTime {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return CFAbsoluteTimeGetCurrent() - startTime
        }
    }
}

extension Color {
    func flattenWithColor(_ foreColor: Color) -> Color {
        return flattenColors(self, withColor: foreColor)
    }
    
    func toRGBA() -> Int32 {
        func denormalize(_ value: CGFloat) -> Int32 {
            return Int32(max(0, min(255, value * 255)))
        }
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let ret: Int32 = (denormalize(alpha) << 24) | (denormalize(red) << 16) | (denormalize(green) << 8) | (denormalize(blue))
        
        return ret
    }
    
    static func fromARGB(_ argb: Int32) -> Color {
        let blue = argb & 0xff
        let green = argb >> 8 & 0xff
        let red = argb >> 16 & 0xff
        let alpha = argb >> 24 & 0xff
        
        return Color(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha) / 255.0)
    }
    
    static func fromUInt(_ color: UInt) -> Color {
        let a = CGFloat((color >> 24) & 0xFF) / 255.0
        let r = CGFloat((color >> 16) & 0xFF) / 255.0
        let g = CGFloat((color >> 8) & 0xFF) / 255.0
        let b = CGFloat(color & 0xFF) / 255.0
        
        return Color(red: r, green: g, blue: b, alpha: a)
    }
}

func flattenColors(_ backColor: Color, withColor foreColor: Color) -> Color {
    // Based off an answer by an anonymous user on StackOverlow http://stackoverflow.com/questions/1718825/blend-formula-for-gdi/2223241#2223241
    var backR: CGFloat = 0, backG: CGFloat = 0, backB: CGFloat = 0, backA: CGFloat = 0
    
    var foreR: CGFloat = 0, foreG: CGFloat = 0, foreB: CGFloat = 0, foreA: CGFloat = 0
    
    backColor.getRed(&backR, green: &backG, blue: &backB, alpha: &backA)
    foreColor.getRed(&foreR, green: &foreG, blue: &foreB, alpha: &foreA)
    
    if (foreA == 0) {
        return backColor
    }
    if (foreA == 1) {
        return foreColor
    }
    
    let backAlphaFloat = backA
    let foreAlphaFloat = foreA
    
    let foreAlphaNormalized = foreAlphaFloat
    let backColorMultiplier = backAlphaFloat * (1 - foreAlphaNormalized)
    
    let alpha = backAlphaFloat + foreAlphaFloat - backAlphaFloat * foreAlphaNormalized
    
    return Color(red: min(1, (foreR * foreAlphaFloat + backR * backColorMultiplier) / alpha),
                 green: min(1, (foreG * foreAlphaFloat + backG * backColorMultiplier) / alpha),
                 blue: min(1, (foreB * foreAlphaFloat + backB * backColorMultiplier) / alpha),
                 alpha: alpha)
}
