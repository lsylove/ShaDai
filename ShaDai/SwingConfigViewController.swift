//
//  SwingConfigViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 19..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVKit
import AVFoundation

class SwingConfigViewController: UIViewController {
    
    var targetPlayer = AVPlayer()
    
    var state = 0
    
    @IBOutlet weak var stateBar: UIView!
    
    @IBOutlet weak var state1: UIButton!

    @IBOutlet weak var state2: UIButton!
    
    @IBOutlet weak var state3: UIButton!
    
    @IBOutlet weak var state4: UIButton!
    
    @IBOutlet weak var state5: UIButton!
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var playerView: PlayerView!
    
    var pointLocations = [UIView]()
    
    var points = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        playerView.player = targetPlayer
        updatePlaySlide(item: targetPlayer.currentItem!)
        
        stateBar.layer.borderWidth = 2.0
        stateBar.layer.borderColor = UIColor.black.cgColor
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for i in 0..<5 {
            let loc = UIView()
            loc.frame = CGRect(x: i * 10, y: 0, width: 2, height: Int(stateBar.frame.height))
            
            loc.backgroundColor = .red
            
            pointLocations.append(loc)
            stateBar.addSubview(loc)
        }
        
    }
    
    @IBAction func onStateButton(_ sender: UIButton) {
        switch sender {
        case state1: state = 0
        case state2: state = 1
        case state3: state = 2
        case state4: state = 3
        case state5: state = 4
        default: state = 0
        }
    }
    
    @IBAction func onSlide(_ sender: Any, forEvent event: UIEvent) {
        let durationTime = targetPlayer.currentItem!.asset.duration
        let duration = CMTimeGetSeconds(durationTime)
        
        var sec = Double(slider.value) * duration
        var ts = durationTime.timescale
        
        if (sec < 1.002) {
            sec = 0.002
            ts = 3
        } else if (sec > duration - 1.012) {
            sec = duration - 0.012
        }
        
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
