//
//  DualViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 19..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVFoundation
import AVKit

class DualViewController: UIViewController, UnwindDelegate {

    @IBOutlet weak var first: PlayerView!
    
    @IBOutlet weak var second: PlayerView!
    
    @IBOutlet weak var firstField: UITextField!
    
    @IBOutlet weak var secondField: UITextField!
    
    @IBOutlet weak var firstLoad: UIButton!
    
    @IBOutlet weak var secondLoad: UIButton!
    
    @IBOutlet weak var firstConfig: UIButton!
    
    @IBOutlet weak var secondConfig: UIButton!
    
    @IBOutlet weak var playSlider: UISlider!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var pauseButton: UIButton!
    
    @IBOutlet weak var prevButton: UIButton!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var firstHindrance: UIView!
    
    @IBOutlet weak var secondHindrance: UIView!
    
    @IBOutlet weak var firstBar: BarIndicatorView!
    
    @IBOutlet weak var secondBar: BarIndicatorView!
    
    var params: TimemarkParams<PlayerView>!
    
    var tempParams: [AVPlayer:[Double]] = [:]
    
    var timer: Timer?
    
    let fps = 30.0
    
    let ticks = 50.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        firstConfig.isEnabled = false
        secondConfig.isEnabled = false
        
        firstBar.isHidden = true
        secondBar.isHidden = true
        
        playControlState(false)
        pauseButton.isHidden = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.cancelEdit))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        first.player?.seek(to: CMTime(seconds: 0.002, preferredTimescale: 1))
        second.player?.seek(to: CMTime(seconds: 0.002, preferredTimescale: 1))
        
        playSlider.value = 0.0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pause()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "config") {
            let dst = segue.destination as! SwingConfigViewController
            let target = sender as! UIButton
            
            dst.delegate = self
            
            let isFirst = target == firstConfig
            
            dst.targetPlayer = isFirst ? first.player! : second.player!
            dst.targetPlayer.pause()
            
            if let cached = tempParams[dst.targetPlayer] {
                dst.points = cached
            }
        }
    }
    
    func unwind(controller: UIViewController) {
        guard let src = controller as? SwingConfigViewController else {
            return
        }
        
        let isFirst = src.targetPlayer == first.player
        var ret = false
        
        tempParams[src.targetPlayer] = src.points
        
        for (index, value) in src.points.enumerated() {
            if value < 0.0 {
                ret = true
            } else if let swingMotion = SwingMotion(rawValue: index) {
                (isFirst ? firstBar : secondBar).addIndicator(identifier: swingMotion.identifier,
                                                              color: swingMotion.barColor,
                                                              value: Float(value),
                                                              priority: swingMotion.orderPriority)
            }
        }
        
        if !ret {
            updateFrame(src.points, isFirst: isFirst)
        }
    }

    @IBAction func action(_ sender: UIButton) {
        switch sender {
        case firstLoad, secondLoad: load(sender, isFirst: sender == firstLoad)
        case playButton: play()
        case pauseButton: pause()
        case prevButton, nextButton: moveOneFrame(sender, isPrev: sender == prevButton)
        default: print("[debug] action bind failure")
        }
    }
    
    @IBAction func slide(_ sender: UISlider) {
        moveFrame(Double(sender.value))
    }
    
    func load(_ sender: UIButton, isFirst: Bool) {
        let (field, obj, config, hindrance, bar) = isFirst ? (firstField!, first!, firstConfig!, firstHindrance!, firstBar!) : (secondField!, second!, secondConfig!, secondHindrance!, secondBar!)
        
        cancelEdit()
        
        guard let path = Bundle.main.path(forResource: field.text, ofType: "mp4") else {
            print("[debug] resource not found")
            showMessage("Resource not found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        let playerItem = AVPlayerItem(url: url)
        
        obj.player = AVPlayer(playerItem: playerItem)
        
        sender.isEnabled = false
        config.isEnabled = true
        
        DispatchQueue.global().async {
            while (playerItem.status != .readyToPlay) {
                
            }
            DispatchQueue.main.async {
                let layer = obj.playerLayer
                let vr = layer.videoRect
                
                bar.isHidden = false
                bar.frame = CGRect(x: layer.frame.minX + vr.minX, y: layer.frame.maxY, width: vr.width, height: 10)
                bar.setNeedsLayout()
                
                hindrance.bounds = obj.playerLayer.videoRect
                hindrance.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 0.75)
            }
        }
    }
    
    func tick() {
        var rate = Double(playSlider.value)
        let duration = params.timemarks.last!
        let trackTime = rate * duration
        
        if (rate > 0.999) {
            pause()
        }
        
        for playerView in [first!, second!] {
            let player = playerView.player!
            if (player.timeControlStatus == .playing) {
                if (params.shouldPause(playerView, trackTime: trackTime)) {
                    player.pause()
                }
                
            } else if (player.timeControlStatus == .paused) {
                if (!params.shouldPause(playerView, trackTime: trackTime)) {
                    player.play()
                }
                
            }
        }
        
        rate += 1 / duration / ticks
        DispatchQueue.main.async {
            self.playSlider.value = Float(rate)
        }
    }
    
    func play() {
        if (playSlider.value > 0.999) {
            DispatchQueue.main.async {
                self.playSlider.value = 0.001
                self.moveFrame(0.001)
            }
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0 / ticks, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        
        playButton.isHidden = true
        pauseButton.isHidden = false
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        
        first.player?.pause()
        second.player?.pause()
        
        playButton.isHidden = false
        pauseButton.isHidden = true
    }
    
    func moveOneFrame(_ sender: UIButton, isPrev: Bool) {
        var rate = Double(playSlider.value)
        let duration = params.timemarks.last!
        
        rate += 1 / duration / fps * (isPrev ? -1 : 1)
        moveFrame(rate)
        DispatchQueue.main.async {
            self.playSlider.value = Float(rate)
        }
    }
    
    func moveFrame(_ rate: Double) {
        let duration = params.timemarks.last!
        let trackTime = rate * duration
        
        let firstPlayTime = params.trackTimeToPlayTime(first, trackTime: trackTime)
        let secondPlayTime = params.trackTimeToPlayTime(second, trackTime: trackTime)
        
        let firstItem = first.player!.currentItem!
        let secondItem = second.player!.currentItem!
        
        firstItem.step(byCount: Int(fps * (firstPlayTime - CMTimeGetSeconds(firstItem.currentTime()))))
        secondItem.step(byCount: Int(fps * (secondPlayTime - CMTimeGetSeconds(secondItem.currentTime()))))
    }
    
    func updateFrame(_ points: [Double], isFirst: Bool) {
        // (isFirst ? firstSwingTime : secondSwingTime) = obj.currentTime()
        
        (isFirst ? firstHindrance : secondHindrance)?.isHidden = true
        
        if (firstHindrance.isHidden && secondHindrance.isHidden) {
            calculateParameters(points, isFirst: isFirst)
            
            if (!playSlider.isEnabled) {
                playControlState(true)
                initializeVideo()
            }
        }
    }
    
    func cancelEdit() {
        view.endEditing(true)
    }
    
    private func initializeVideo() {
        first.player!.actionAtItemEnd = .pause
        second.player!.actionAtItemEnd = .pause
    }
    
    private func playControlState(_ state: Bool) {
        playSlider.isEnabled = state
        playButton.isEnabled = state
        
        prevButton.isEnabled = state
        nextButton.isEnabled = state
    }
    
    private func calculateParameters(_ points: [Double], isFirst: Bool) {
        let (ad, bd) = (CMTimeGetSeconds(first.player!.currentItem!.duration), CMTimeGetSeconds(second.player!.currentItem!.duration))
        
        let (a, b) = (tempParams[first.player!]!, tempParams[second.player!]!)
        var (ar, br) = (a.map { $0 * ad }, b.map { $0 * bd })
        
        ar.append(ad)
        br.append(bd)
        
        params = TimemarkParams(a: first, b: second, markA: ar, markB: br)
    }
    
    private func showMessage(_ message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Message", message: message, preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true)
        }
    }
}
