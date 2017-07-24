//
//  SwingConfigViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 19..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVKit
import AVFoundation

enum SwingMotion: Int {

    case address
    case backSwingTop
    case impact
    case finish
    
    var barColor: UIColor {

        switch self {
        case .address:
            return .white
        case .backSwingTop:
            return .yellow
        case .impact:
            return .green
        case .finish:
            return .cyan
        }
    }
    var identifier: String {
        
        switch self {
        case .address:
            return "address"
        case .backSwingTop:
            return "backSwingTop"
        case .impact:
            return "impact"
        case .finish:
            return "finish"
        }
    }
    var orderPriority: Int {
        return self.rawValue
    }
}

protocol UnwindDelegate {
    func unwind(controller: UIViewController)
}

class SwingConfigViewController: UIViewController {
    
    var targetPlayer = AVPlayer()
    
    var state = 0
    
    @IBOutlet weak var stateBar: BarIndicatorView!
    @IBOutlet weak var motionSegment: UISegmentedControl!
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var playerView: PlayerView!
    
    var pointLocations = [UIView]()
    
    var points = [Double](repeating: -1.0, count: 4) // SwingMotion.count
    
    var delegate: UnwindDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        playerView.player = targetPlayer
        updatePlaySlide(item: targetPlayer.currentItem!)
        
        stateBar.layer.borderWidth = 1.0
        stateBar.layer.borderColor = UIColor.gray.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for (index, value) in points.enumerated() {
            if value >= 0.0, let swingMotion = SwingMotion(rawValue: index) {
                self.stateBar.addIndicator(identifier: swingMotion.identifier,
                                                         color: swingMotion.barColor,
                                                         value: Float(value),
                                                         priority: swingMotion.orderPriority)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        delegate?.unwind(controller: self)
    }
    
    @IBAction func onAdd() {
        
        if let swingMotion = SwingMotion(rawValue: self.motionSegment.selectedSegmentIndex) {
            
            let success = self.stateBar.addIndicator(identifier: swingMotion.identifier,
                                                     color: swingMotion.barColor,
                                                     value: self.slider.value,
                                                     priority: swingMotion.orderPriority)
            if success {
                points[swingMotion.orderPriority] = Double(self.slider.value)
                
                if self.motionSegment.selectedSegmentIndex < 3 {
                    self.motionSegment.selectedSegmentIndex += 1
                }
            }
            else {
                
                let alert = UIAlertController(title: "순서가 맞지 않습니다.", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .destructive, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func onSlide(_ sender: Any, forEvent event: UIEvent) {
        let durationTime = targetPlayer.currentItem!.asset.duration
        let duration = CMTimeGetSeconds(durationTime)
        
        let sec = Double(slider.value) * duration
        let ts = durationTime.timescale
        
        targetPlayer.seek(to: CMTimeMakeWithSeconds(sec, ts), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
    
    @IBAction func onPrevButton(_ sender: Any) {
        let item = targetPlayer.currentItem!
        
        if (item.canStepBackward) {
            item.step(byCount: -1)
            updatePlaySlide(item: item)
        }

    }

    @IBAction func onNextButton(_ sender: Any) {
        let item = targetPlayer.currentItem!
        
        if (item.canStepForward) {
            item.step(byCount: 1)
            updatePlaySlide(item: item)
        }
    }
    
    func updatePlaySlide(item: AVPlayerItem) {
        slider.value = Float(CMTimeGetSeconds(item.currentTime()) / CMTimeGetSeconds(item.asset.duration))
    }
}
