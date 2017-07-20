//
//  DualViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 19..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVFoundation
import AVKit

class DualViewController: UIViewController {

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
    
    @IBOutlet weak var prevButton: UIButton!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var firstHindrance: UIView!
    
    @IBOutlet weak var secondHindrance: UIView!
    
    var params: TimemarkParams<PlayerView>!
    
    var tempParams: [Double]?
    
    var timer: Timer?
    
    let fps = 30.0
    
    let ticks = 50.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        firstConfig.isEnabled = false
        secondConfig.isEnabled = false
        
        playControlState(false)
        
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
            
            dst.targetPlayer = target == firstConfig ? first.player! : second.player!
            dst.targetPlayer.pause()
        }
    }
    
    var i = 0
    var test = [[0.4, 1.6, 2.4, 3.2, 4], [1.2, 1.5, 1.7, 3.9, 4], [0.2, 0.6, 1.5, 2.5, 4]]
    
    @IBAction func unwinded(segue: UIStoryboardSegue, sender: Any?) {
        let src = segue.source as! SwingConfigViewController
        
        updateFrame(test[i % 3], isFirst: src.targetPlayer == first.player)
        i += 1
    }

    @IBAction func action(_ sender: UIButton) {
        switch sender {
        case firstLoad, secondLoad: load(sender, isFirst: sender == firstLoad)
        case playButton: sender.titleLabel!.text == "Play" ? play() : pause()
        case prevButton, nextButton: moveOneFrame(sender, isPrev: sender == prevButton)
        default: print("[debug] action bind failure")
        }
    }
    
    @IBAction func slide(_ sender: UISlider) {
        moveFrame(Double(sender.value))
    }
    
    func load(_ sender: UIButton, isFirst: Bool) {
        let (field, obj, config, hindrance) = isFirst ? (firstField!, first!, firstConfig!, firstHindrance!) : (secondField!, second!, secondConfig!, secondHindrance!)
        
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
                hindrance.bounds = obj.playerLayer.videoRect
                hindrance.backgroundColor = UIColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 0.75)
            }
        }
    }
    
    func tick() {
        var rate = Double(playSlider.value)
        let duration = params.timemarks.last!
        let trackTime = rate * duration
        
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
        
        if (rate > 0.999) {
            pause()
        }
    }
    
    func play() {
        timer = Timer.scheduledTimer(timeInterval: 1.0 / ticks, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        
        playButton.setTitle("Pause", for: .normal)
    }
    
    func pause() {
        timer?.invalidate()
        timer = nil
        
        playButton.setTitle("Play", for: .normal)
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
    
    func updatePlaySlide() {
        DispatchQueue.main.async {
        }
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
        
        tempParams = points
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
        let (a, b) = isFirst ? (points, params?.mark[second] ?? tempParams!) : (params?.mark[first] ?? tempParams!, points)
        params = TimemarkParams(a: first, b: second, markA: a, markB: b)
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
