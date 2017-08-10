//
//  ProfileTwoViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 8. 10..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVKit
import AVFoundation

class ProfileTwoViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var playSlider: UISlider!
    
    @IBOutlet weak var playStepper: UIStepper!
    
    @IBOutlet weak var playerView: PlayerView!
    
    @IBOutlet weak var loadButton: UIButton!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var hindrance: UIView!
    
    @IBOutlet weak var markLabel: UILabel!
    
    @IBOutlet weak var clearButton: UIButton!
    
    @IBOutlet weak var doneButton: UIButton!
    
    var fps = 30.0
    
    var duration = 0.0
    
    var sliderPrev = 0.0
    
    var stepperPrev = 0.0

    @IBAction func playSlider(_ sender: UISlider) {
        let valueDiff = Double(sender.value) - sliderPrev
        
        if (valueDiff > 0.0002 || valueDiff < -0.0002) {
            let diff = valueDiff * fps * duration
            updateControlPosition(value: diff, stepper: playStepper)
            updatePlayPositionAbsolute(value: Double(sender.value))
//            updatePlayPosition(value: Int(diff))
        }
        
        sliderPrev = Double(sender.value)
    }
    
    @IBAction func playStepper(_ sender: UIStepper) {
        if (sender.value != stepperPrev) {
            let diff = sender.value - stepperPrev
            updateControlPosition(value: diff, slider: playSlider)
            updatePlayPosition(value: Int(diff))
            
            stepperPrev = sender.value
        }
        
    }
    
    @IBAction func loadButton(_ sender: UIButton) {
        DispatchQueue.global().async {
            self.load()
        }
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        DispatchQueue.global().async {
            self.save()
        }
    }
    
    @IBAction func markButton(_ sender: UIBarButtonItem) {
        if playerView.player == nil {
            return
        }
        
        if markLabel.isHidden {
            startMarkEditing()
            
        } else {
            endMarkEditing()
            
        }
    }
    
    @IBAction func clearButton(_ sender: UIButton) {
        destroyPath()
    }
    
    @IBAction func doneButton(_ sender: UIButton) {
        endMarkEditing()
    }
    
    func showMessage(_ message: String = "alert") {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true)
        }
    }
    
    // >_< -> properties reserved for extensions
    
    var pathLayer = CALayer()
    
    var path = UIBezierPath()
    
}

extension ProfileTwoViewController {
    
    func initHindrance() {
        let outer = playerView.frame
        let inner = playerView.playerLayer.videoRect
        
        let center = CGPoint(x: outer.minX + inner.minX, y: outer.minY + inner.minY)
        hindrance.frame = CGRect(origin: center, size: inner.size)
        
        hindrance.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.onHindranceTouch)))
        hindrance.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onHindranceTouch)))
        
        pathLayer.frame = hindrance.bounds
        hindrance.layer.mask = pathLayer
        
        path.lineWidth = 16
        
        updatePathDrawing()
    }
    
    func onHindranceTouch(recognizer: UIGestureRecognizer) {
        let point = recognizer.location(in: hindrance)
        
        if let panRecognizer = recognizer as? UIPanGestureRecognizer {
            switch panRecognizer.state {
            case .began: path.move(to: point)
            case .changed, .ended: path.addLine(to: point); updatePathDrawing()
            default: break
            }
            
        } else {
            path.move(to: point)
            path.addLine(to: CGPoint(x: point.x + 16.0, y: point.y))
            updatePathDrawing()
        }
    }
    
    func startMarkEditing() {
        
        saveButton.isEnabled = false
        [hindrance, markLabel, clearButton, doneButton].forEach { $0.isHidden = false }
    }
    
    func endMarkEditing() {
        
        saveButton.isEnabled = true
        [hindrance, markLabel, clearButton, doneButton].forEach { $0.isHidden = true }
    }
    
    func destroyPath() {
        path = UIBezierPath()
        path.lineWidth = 16
        
        updatePathDrawing()
    }
    
    func updatePathDrawing() {
        UIGraphicsBeginImageContext(pathLayer.bounds.size)
        
        UIColor.white.setFill()
        UIColor.black.setStroke()
        
        UIRectFill(pathLayer.bounds)
        path.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let ciimage = CIImage(image: image)
        let filter = CIFilter(name: "CIMaskToAlpha")!
        filter.setValue(ciimage, forKey: "inputImage")
        let filtered = filter.outputImage!
        
        let cgimage = CIContext().createCGImage(filtered, from: filtered.extent)
        pathLayer.contents = cgimage
    }
    
}

extension ProfileTwoViewController {
    
    func load() {
        guard let path = Bundle.main.path(forResource: textField.text ?? "", ofType: nil) else {
            showMessage("No such file!")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url)
        
        guard let track = asset.tracks(withMediaType: AVMediaTypeVideo).first else {
            showMessage("Not a valid video file!")
            return
        }
        
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        
        playerView.player = player
        
        fps = Double(track.nominalFrameRate)
        duration = CMTimeGetSeconds(asset.duration)
        
        DispatchQueue.main.async {
            self.loadControls()
        }
        
        while (playerItem.status != .readyToPlay) {
            
        }
        DispatchQueue.main.async {
            self.initHindrance()
        }
    }
    
    func loadControls() {
        playStepper.maximumValue = fps * duration
        
        loadButton.isEnabled = false
        saveButton.isEnabled = true
        
        textField.isEnabled = false
        playSlider.isEnabled = true
        playStepper.isEnabled = true
    }
    
    // value: # of frames changed
    func updateControlPosition(value: Double, slider: UISlider? = nil, stepper: UIStepper? = nil) {
        slider?.value += Float(value / fps / duration)
        stepper?.value += value
        
        stepperPrev = stepper?.value ?? stepperPrev
    }
    
    // value: # of frames changed
    func updatePlayPosition(value: Int) {
        playerView.player!.currentItem!.step(byCount: value)
    }
    
    // value: absolute position (between 0 and 1)
    func updatePlayPositionAbsolute(value: Double) {
        let val = CMTime(seconds: value * duration, preferredTimescale: 1000)
        let mil = CMTime(seconds: 0.001, preferredTimescale: 1000)
        
        playerView.player!.seek(to: val, toleranceBefore: mil, toleranceAfter: mil)
    }
    
}

extension ProfileTwoViewController {
    
    func save() {
        
    }
    
}
