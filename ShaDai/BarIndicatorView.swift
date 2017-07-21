//
//  BarIndicatorView.swift
//  ShaDai
//
//  Created by chicpark7 on 20/07/2017.
//  Copyright © 2017 WebLinkTest. All rights reserved.
//

import UIKit

struct BarIndicator {
    
    var identifier: String
    var color: UIColor
    var value: Float
    var orderPrority: Int
    
}

class BarIndicatorView: UIView {
    
    override func draw(_ rect: CGRect) {
        
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        
        for indicator in indicators {
            let x = rect.width * CGFloat(indicator.value)
            context?.move(to: CGPoint(x: x, y: 0))
            context?.addLine(to: CGPoint(x: x, y: rect.height))
            context?.setLineWidth(2)
            indicator.color.setStroke()
            context?.strokePath()
        }
    }
    
    public var indicators = [BarIndicator]()
    
    @discardableResult
    public func addIndicator(identifier: String, color: UIColor, value: Float, priority: Int) -> Bool {
        
        for indicator in indicators {
            if ((indicator.value > value) != (indicator.orderPrority > priority)
                && indicator.identifier != identifier) {
                return false
            }
        }
        
        if let index = indicators.index(where: { $0.identifier == identifier }) {
            
            indicators.remove(at: index)
            
        }
        
        indicators.append(BarIndicator(identifier: identifier, color: color, value: value, orderPrority: priority))
        
        self.setNeedsDisplay()
        
        return true
    }
}
