//
//  ShapeView.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 26..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit

protocol ShapeViewGestureRecognitionDelegate: class {
    func shapeViewGestureRecognition(_ view: ShapeView, recognizer: UIGestureRecognizer, operation: Any)
}

enum Shape: Int {
    case line = 0
    case square
    case circle
    
    func recipe() -> ((UIBezierPath, CGPoint, CGPoint) -> Void) {
        switch self {
        case .line: return { path, a, b in
            path.move(to: a)
            path.addLine(to: b)
            }
        case .square: return { path, a, b in
            path.move(to: a)
            path.addLine(to: CGPoint(x: a.x, y: b.y))
            path.addLine(to: b)
            path.addLine(to: CGPoint(x: b.x, y: a.y))
            path.addLine(to: a)
            }
        case .circle: return { path, a, b in
            let center = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            let radius = Swift.min(Swift.abs(a.x - b.x), Swift.abs(a.y - b.y)) / 2
            path.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat(Float.pi * 2), clockwise: true)
            }
        }
    }
}

class ShapeView: UIView {
    
    var a: CGPoint
    
    var b: CGPoint
    
    var c: UIColor {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    var d: (UIBezierPath, CGPoint, CGPoint) -> Void {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    let f: CGRect
    
    var absA: CGPoint {
        didSet {
            calculatePosition()
            calculateFrames()
        }
    }
    
    var absB: CGPoint {
        didSet {
            calculatePosition()
            calculateFrames()
        }
    }
    
    private static let r: CGFloat = 6.0
    
    private let r: CGFloat = ShapeView.r
    
    private let aView = UIView()
    
    private let bView = UIView()
    
    private let dView = UIView()
    
    var isSelected: Bool {
        set {
            [aView, bView, dView].forEach { $0.isHidden = !newValue }
            self.setNeedsDisplay()
        } get {
            return !aView.isHidden
        }
    }
    
    weak var delegate: ShapeViewGestureRecognitionDelegate?
    
    init(a: CGPoint, b: CGPoint, c: UIColor, f: CGRect, d: @escaping (UIBezierPath, CGPoint, CGPoint) -> Void) {
        let mx = Swift.min(a.x, b.x)
        let my = Swift.min(a.y, b.y)
        
        self.a = CGPoint(x: a.x - mx, y: a.y - my)
        self.b = CGPoint(x: b.x - mx, y: b.y - my)
        self.c = c
        self.d = d
        self.f = f
        
        absA = a
        absB = b
        
        super.init(frame: CGRect())
        calculateFrames()
        
        [aView, bView, dView].forEach {
            let recognizer = UIPanGestureRecognizer(target: self, action: #selector(self.pan))
            $0.addGestureRecognizer(recognizer)
        }
        
        self.addSubview(dView)
        self.addSubview(aView)
        self.addSubview(bView)
        
        self.backgroundColor = UIColor.clear
        aView.backgroundColor = UIColor.clear
        bView.backgroundColor = UIColor.clear
        dView.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    private func calculatePosition() {
        let mx = Swift.min(absA.x, absB.x)
        let my = Swift.min(absA.y, absB.y)
        
        a = CGPoint(x: absA.x - mx, y: absA.y - my)
        b = CGPoint(x: absB.x - mx, y: absB.y - my)
    }
    
    private func calculateFrames() {
        self.frame = CGRect(x: Swift.min(absA.x, absB.x) - r * 2, y: Swift.min(absA.y, absB.y) - r * 2, width: Swift.abs(absA.x - absB.x) + r * 4, height: Swift.abs(absA.y - absB.y) + r * 4)
        
        aView.frame = CGRect(x: a.x, y: a.y, width: r * 4, height: r * 4)
        bView.frame = CGRect(x: b.x, y: b.y, width: r * 4, height: r * 4)
        dView.frame = CGRect(x: r * 2, y: r * 2, width: Swift.abs(a.x - b.x), height: Swift.abs(a.y - b.y))
    }
    
    private func check(_ transposed: CGPoint) -> Bool {
        return f.contains(transposed)
    }
    
    @objc private func pan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        
        let operation: (ShapeView, CGPoint) -> Void
        switch (recognizer.view ?? UIView()) {
        case aView: operation = moveA
        case bView: operation = moveB
        case dView: operation = transpose
        default: operation = moveB
        }
        operation(self, translation)
        
        delegate?.shapeViewGestureRecognition(self, recognizer: recognizer, operation: operation)
        recognizer.setTranslation(CGPoint(), in: self)
    }
    
    func moveA(target: ShapeView, by: CGPoint) {
        target.movePoint(lv: &target.absA, by: by)
    }
    
    func moveB(target: ShapeView, by: CGPoint) {
        target.movePoint(lv: &target.absB, by: by)
    }
    
    func transpose(target: ShapeView, by: CGPoint) {
        target.transposeInternal(by: by)
    }
    
    private func movePoint(lv: inout CGPoint, by: CGPoint) {
        guard check(CGPoint(x: lv.x + by.x, y: lv.y + by.y)) else {
            return
        }
        
        lv.x += by.x
        lv.y += by.y
        
        calculatePosition()
        calculateFrames()
        
        self.setNeedsDisplay()
    }
    
    private func transposeInternal(by: CGPoint) {
        absA.x += by.x
        absA.y += by.y
        absB.x += by.x
        absB.y += by.y
        
        if (!check(absA) || !check(absB)) {
            absA.x -= by.x
            absA.y -= by.y
            absB.x -= by.x
            absB.y -= by.y
            return
        }
        
        calculatePosition()
        calculateFrames()
        
        self.setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        let pi2 = CGFloat(Double.pi * 2)
        let A = CGPoint(x: a.x + r * 2, y: a.y + r * 2)
        let B = CGPoint(x: b.x + r * 2, y: b.y + r * 2)
        
        let path = UIBezierPath()
        d(path, A, B)
        
        c.set()
        path.lineWidth = 1.5
        path.stroke()
        
        UIColor.white.set()
        
        if (!aView.isHidden) {
            let whitePathA = UIBezierPath(arcCenter: A, radius: r, startAngle: 0, endAngle: pi2, clockwise: true)
            whitePathA.lineWidth = 1.5
            whitePathA.stroke()
        }
        
        if (!bView.isHidden) {
            let whitePathB = UIBezierPath(arcCenter: B, radius: r, startAngle: 0, endAngle: pi2, clockwise: true)
            whitePathB.lineWidth = 1.5
            whitePathB.stroke()
        }
    }
}

extension ShapeView: NSCopying {
    func copy(with: NSZone? = nil) -> Any {
        let shape = ShapeView(a: self.absA, b: self.absB, c: self.c, f: self.f, d: self.d)
        shape.delegate = self.delegate
        shape.isSelected = self.isSelected
        return shape
    }
}
