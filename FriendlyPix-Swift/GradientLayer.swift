//
//  GradientLayer.swift
//  FriendlyPix-Swift
//
//  Created by Kazuki Ohara on 2017/11/11.
//  Copyright © 2017年 Kazuki Ohara. All rights reserved.
//

import Foundation
import QuartzCore

class GradientLayer: CALayer {

    override init() {
        super.init()
        setNeedsDisplay()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(in ctx: CGContext) {
        let gradLocationsNum = 2
        let gradLocations: [CGFloat] = [0.0, 1.0]
        let gradColors: [CGFloat] = [0.01, 0.61, 0.90, 1.0, 0.0, 0.34, 0.61, 1.0]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let gradient = CGGradient(colorSpace: colorSpace, colorComponents: gradColors, locations: gradLocations, count: gradLocationsNum) else {
            return
        }

        let gradCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let gradRadius = min(bounds.size.width, bounds.size.height)

        ctx.drawRadialGradient(gradient, startCenter: gradCenter, startRadius: 0, endCenter: gradCenter, endRadius: gradRadius, options: .drawsAfterEndLocation)
    }

}
