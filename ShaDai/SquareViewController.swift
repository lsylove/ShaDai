//
//  SquareViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 25..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit

class SquareViewController: UIViewController, HSBColorPickerDelegate {
    
    var shapes = [ShapeView]()
    
    var current: ShapeView?

    @IBOutlet weak var shapeSegControl: UISegmentedControl!
    
    @IBOutlet weak var colorButton: UIButton!
    
    @IBOutlet weak var undoButton: UIButton!
    
    @IBOutlet weak var uiView: UIView!
    
    @IBOutlet weak var colorView: UIView!
    
    private let a = CGPoint(x: 100, y: 500)
    
    private let b = CGPoint(x: 200, y: 400)
    
    func shapeSelect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
            self.appendShape()
        }
    }
    
    @IBAction func undo(_ sender: UIButton) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.pick)))
        
        let segTap = UITapGestureRecognizer(target: self, action: #selector(self.shapeSelect))
        segTap.cancelsTouchesInView = false
        shapeSegControl.addGestureRecognizer(segTap)
        
        colorView.layer.borderColor = UIColor.black.cgColor
        colorView.layer.borderWidth = 1
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "color") {
            let dst = segue.destination as! ColorPickerViewController
            dst.delegate = self
        }
    }
    
    func HSBColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizerState) {
        colorView.backgroundColor = color
        current?.c = color
    }
    
    // >_<
    
    func pick(recognizer: UITapGestureRecognizer) {
        if (recognizer.state != .ended) {
            return
        }
        
        let point = recognizer.location(in: self.view)
        current?.isSelected = false
        
        if (current?.frame.contains(point) ?? false) {
            var checkup = current == nil
            for shape in shapes.reversed() {
                if (!shape.frame.contains(point)) {
                    continue
                }
                if (shape == current) {
                    checkup = true
                    continue
                }
                if (!checkup) {
                    continue
                }
                registerShape(shape)
                return
            }
            for shape in shapes.reversed() {
                if (!shape.frame.contains(point)) {
                    continue
                }
                if (shape == current) {
                    current = nil
                    return
                }
                registerShape(shape)
                return
            }
            
        } else {
            current = nil
            
            for shape in shapes.reversed() {
                if (!shape.frame.contains(point)) {
                    continue
                }
                registerShape(shape)
                return
            }
        }
    }
    
    private func registerShape(_ shape: ShapeView) {
        shape.isSelected = true
        current = shape
        
        shape.removeFromSuperview()
        self.view.addSubview(shape)
    }
    
    private func appendShape() {
        let shape = Shape(rawValue: shapeSegControl.selectedSegmentIndex)!
        let view = ShapeView(a: a, b: b, c: colorView.backgroundColor!, f: uiView.frame, d: shape.recipe())
        
        shapes.append(view)
        self.view.addSubview(view)
        
        current?.isSelected = false
        current = view
    }
    
    // >_<

}
