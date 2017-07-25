//
//  SquareViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 25..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

enum Shape: Int {
    case line = 0
    case square
    case circle
}

import UIKit

class SquareViewController: UIViewController, HSBColorPickerDelegate {
    
    var shape = Shape.line

    @IBOutlet weak var shapeSegControl: UISegmentedControl!
    
    @IBOutlet weak var colorButton: UIButton!
    
    @IBOutlet weak var undoButton: UIButton!
    
    @IBAction func shapeSegment(_ sender: UISegmentedControl) {
    }
    
    @IBAction func undo(_ sender: UIButton) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        for view in [shapeSegControl, colorButton, undoButton] as [UIView] {
            view.tintColor = color
        }
    }

}
