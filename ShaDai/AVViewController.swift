//
//  AVViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 7..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class AVViewController: UIViewController {

    @IBOutlet weak var playerView: PlayerView!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var slider: UISlider!
    
    var timer: Timer?
    
    override func loadView() {
        super.loadView()
        
        let path = Bundle.main.path(forResource: "video.mp4", ofType: nil)!
        let url = URL(fileURLWithPath: path)
        
        playerView.player = AVPlayer(url: url)
        playerView.playCallback = {
            DispatchQueue.main.async {
                self.playButton.setTitle("Pause", for: .normal)
            }
            
            self.timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(self.updateSlide), userInfo: nil, repeats: true)
        }
        
        playerView.pauseCallback = {
            DispatchQueue.main.async {
                self.playButton.setTitle("Play", for: .normal)
            }
            
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        playerView.player?.actionAtItemEnd = .pause
//        playerView.player?.addPeriodicTimeObserver(forInterval: <#T##CMTime#>, queue: <#T##DispatchQueue?#>, using: <#T##(CMTime) -> Void#>)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.selectPause), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerView.player?.currentItem)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        playerView.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        playerView.pause()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func onPlay(_ sender: Any) {
        playerView.toggle()
    }

    @IBAction func onPrev(_ sender: Any) {
        playerView.pause()
        
        let time: CMTime = playerView.player!.currentTime()
        var sec = CMTimeGetSeconds(time)
        var ts = time.timescale
        
        if (sec > 1.002) {
            sec -= 1.0
        } else {
            sec = 0.002
            ts = 3
        }
        
        playerView.player!.seek(to: CMTimeMakeWithSeconds(sec, ts), toleranceBefore: CMTimeMakeWithSeconds(0.002, 3), toleranceAfter: CMTimeMakeWithSeconds(0.002, 3)) {_ in self.updateSlide()}
    }
    
    @IBAction func onNext(_ sender: Any) {
        playerView.pause()
        
        let time = playerView.player!.currentTime()
        var sec = CMTimeGetSeconds(time)
        
        let durationTime = playerView.player!.currentItem!.asset.duration
        let duration = CMTimeGetSeconds(durationTime)
        var ts = time.timescale
        
        if (sec < duration - 1.012) {
            sec += 1.0
        } else {
            sec = duration - 0.012
            ts = durationTime.timescale
        }
        
        playerView.player!.seek(to: CMTimeMakeWithSeconds(sec, ts), toleranceBefore: CMTimeMakeWithSeconds(0.002, 3), toleranceAfter: CMTimeMakeWithSeconds(0.002, 3)) {_ in self.updateSlide()}
    }
    
    var flag = false
    
    @IBAction func onSlide(_ sender: Any, forEvent event: UIEvent) {

        DispatchQueue.global().async {
            
            let touchEnded = event.allTouches?.first?.phase == nil
            
            if (self.playerView.player!.timeControlStatus == .playing) {
                self.playerView.pause()
                self.flag = true
            }
            
            let durationTime = self.playerView.player!.currentItem!.asset.duration
            let duration = CMTimeGetSeconds(durationTime)
            
            var sec = Double(self.slider.value) * duration
            var ts = durationTime.timescale
            
            if (sec < 1.002) {
                sec = 0.002
                ts = 3
            } else if (sec > duration - 1.012) {
                sec = duration - 0.012
            }
            
            DispatchQueue.main.async {
                self.playerView.player!.seek(to: CMTimeMakeWithSeconds(sec, ts), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) {_ in

                    if (touchEnded && self.flag) {
                        self.flag = false
                        self.playerView.play()
                    }
                }
            }
        }
    }
    
    func updateSlide() {
        let time = (playerView.player?.currentTime())!
        let sec = CMTimeGetSeconds(time)
        
        let durationTime = (playerView.player?.currentItem?.asset.duration)!
        let duration = CMTimeGetSeconds(durationTime)
        
        slider.value = Float(sec / duration)
    }
    
    func selectPause() {
        playerView.pause()
    }
}
