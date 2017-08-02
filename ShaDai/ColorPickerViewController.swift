//
//  ColorPickerViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 24..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit

class ColorPickerViewController: UIViewController {
    
    weak internal var delegate: HSBColorPickerDelegate?

    @IBOutlet weak var colorPicker: HSBColorPicker!
    
    var color: UIColor?
    
    var point: CGPoint?
    
    var state: UIGestureRecognizerState?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        colorPicker.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let color = self.color {
            delegate?.HSBColorPickerTouched(sender: colorPicker, color: color, point: point!, state: state!)
        }
    }

}

extension ColorPickerViewController: HSBColorPickerDelegate {
    
    func HSBColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizerState) {
        self.color = color
        self.point = point
        self.state = state
        
        self.navigationController?.popViewController(animated: true)
        dismiss(animated: true)
    }
    
}
