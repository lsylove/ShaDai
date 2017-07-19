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

    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var playerView: PlayerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        playerView.player = targetPlayer
        updatePlaySlide(item: targetPlayer.currentItem!)
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
