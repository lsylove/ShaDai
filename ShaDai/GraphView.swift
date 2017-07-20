//
//  GraphView.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 18..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit

class GraphView : UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let pa = [CGPoint(x: 100,y: 600), CGPoint(x: 200,y: 500), CGPoint(x: 400,y: 200), CGPoint(x: 600,y: 600), CGPoint(x: 900,y: 0)]
        var curP = CGPoint.zero
        
        let path = UIBezierPath(rect: rect)
        path.move(to: curP)
        
        pa.forEach { (point) in
            
            let midPoint = midPointForPoints(p1: point, p2: curP)
            
            path.addQuadCurve(to: midPoint, controlPoint: controlPointForPoints(p1: midPoint, p2: curP))
            path.addQuadCurve(to: point, controlPoint: controlPointForPoints(p1: midPoint, p2: point))
            
            curP = point
            
        }
        
        path.lineWidth = 2
        UIColor.white.setStroke()
        
        path.stroke()
        
        pa.forEach { (p) in
            // drawDot(point: p)
        }
        
        
    }
    
    func drawDot(point: CGPoint) {
        let radius: CGFloat = 20
        let circle = UIBezierPath(roundedRect: CGRect(x: point.x - radius / 2, y: point.y - radius / 2, width: radius, height: radius), cornerRadius: 10)
        UIColor.red.setFill()
        circle.fill()
        
    }
    
    func midPointForPoints(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2);
    }
    
    func controlPointForPoints(p1: CGPoint, p2: CGPoint) -> CGPoint {
        var controlPoint = midPointForPoints(p1: p1, p2: p2);
        let diffY = abs(p2.y - controlPoint.y);
        
        if (p1.y < p2.y) {
            controlPoint.y += diffY
        }
        else if (p1.y > p2.y) {
            controlPoint.y -= diffY
        }
        
        return controlPoint;
    }
}
