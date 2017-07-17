//
//  TracerViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 14..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit

class TracerViewController: UIViewController {

    @IBOutlet weak var srcView: UIView!
    
    @IBOutlet weak var dstView: UIView!
    
    @IBOutlet weak var slider: UISlider!
    
    let deviceSize = UIScreen.main.bounds
    
    let shape = CAShapeLayer()
    
    var convexity: CGFloat = 1.5
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let srcX: CGFloat = 0.25, srcY: CGFloat = 0.5, dstX: CGFloat = 0.75, dstY: CGFloat = 0.45
        
        self.srcView.layer.cornerRadius = 12
        self.srcView.layer.masksToBounds = true
        self.srcView.frame = CGRect(x: srcX * self.deviceSize.width, y: srcY * self.deviceSize.height, width: 24, height: 24)
        
        self.dstView.layer.cornerRadius = 12
        self.dstView.layer.masksToBounds = true
        self.dstView.frame = CGRect(x: dstX * self.deviceSize.width, y: dstY * self.deviceSize.height, width: 24, height: 24)
        
        let srcMove = UIPanGestureRecognizer(target: self, action: #selector(self.move))
        self.srcView.addGestureRecognizer(srcMove)
        
        let dstMove = UIPanGestureRecognizer(target: self, action: #selector(self.move))
        self.dstView.addGestureRecognizer(dstMove)
        
        self.shape.frame = CGRect(x: 0, y: 0, width: self.deviceSize.width, height: self.deviceSize.height)
        self.shape.fillColor = UIColor.clear.cgColor
        self.shape.strokeColor = UIColor.cyan.cgColor
        self.shape.strokeStart = 0
        self.shape.strokeEnd = 1
        self.shape.opacity = 0.75
        self.shape.lineWidth = 3
        
        self.view.layer.addSublayer(self.shape)
        
        self.reDraw()
    }

    func move(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            let xPos = view.center.x + translation.x, yPos = view.center.y + translation.y
            
            if (xPos > 20 && xPos < self.deviceSize.width - 20 && yPos > 100 && yPos < self.deviceSize.height - 150) {
                view.center = CGPoint(x: xPos, y: yPos)
                reDraw()
            }
        }
        recognizer.setTranslation(CGPoint(), in: self.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func reDraw() {
        let path = UIBezierPath()
        
//        Swift.max(src.center.y, dst.center.y)
        let conX = (srcView.center.x + dstView.center.x * 9) / 10
        let conY = Swift.min(srcView.center.y, dstView.center.y) + Swift.abs(srcView.center.x - dstView.center.x) * convexity - deviceSize.height
        
        
        var start = CGPoint(x: srcView.center.x - 12, y: srcView.center.y)
        let end = CGPoint(x: dstView.center.x, y: dstView.center.y)
        var control = CGPoint(x: conX, y: conY)
        
        for _ in 0..<9 {
            path.move(to: end)
            path.addQuadCurve(to: start, controlPoint: control)
            
            start.x += 2.65
            control.x += 0.5
            control.y += 0.25
        }
        
        shape.path = path.cgPath
    }

    @IBAction func onDraw(_ sender: Any) {
        reDraw()
    }
    
    @IBAction func onSlide(_ sender: Any) {
        convexity = CGFloat(3.0 - slider.value * 3.0)
        reDraw()
    }
}
