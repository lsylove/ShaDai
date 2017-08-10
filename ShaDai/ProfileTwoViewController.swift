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
            updatePlayPosition(value: Int(diff))
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
    
    var pathLayer = CAShapeLayer()
    
    var path = UIBezierPath()
    
    var pathPoint = CGPoint()
    
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

        pathLayer.backgroundColor = UIColor.white.cgColor
        pathLayer.fillColor = UIColor.white.cgColor
        pathLayer.strokeColor = UIColor.clear.cgColor
        pathLayer.lineWidth = 8

        pathLayer.path = path.cgPath
    }
    
    func onHindranceTouch(recognizer: UIGestureRecognizer) {
        print(recognizer.location(in: hindrance))
    }
    
    func startMarkEditing() {
        
        [saveButton, playSlider, playStepper].forEach { $0.isEnabled = false }
        [hindrance, markLabel, clearButton, doneButton].forEach { $0.isHidden = false }
    }
    
    func endMarkEditing() {
        
        [saveButton, playSlider, playStepper].forEach { $0.isEnabled = true }
        [hindrance, markLabel, clearButton, doneButton].forEach { $0.isHidden = true }
    }
    
    func destroyPath() {
        path = UIBezierPath()
        pathLayer.path = path.cgPath
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
    
    func updateControlPosition(value: Double, slider: UISlider? = nil, stepper: UIStepper? = nil) {
        slider?.value += Float(value / fps / duration)
        stepper?.value += value
        
        stepperPrev = stepper?.value ?? stepperPrev
    }
    
    func updatePlayPosition(value: Int) {
        playerView.player!.currentItem!.step(byCount: value)
    }
    
}

extension ProfileTwoViewController {
    
    func save() {
        
    }
    
}
