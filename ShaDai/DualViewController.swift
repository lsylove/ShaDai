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
    
    var pointsFirst = [Double]()
    
    var pointsSecond = [Double]()
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        firstConfig.isEnabled = false
        secondConfig.isEnabled = false
        
        playControlState(false)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.cancelEdit))
        view.addGestureRecognizer(tap)
        
        for playerView in [first!, second!] {
            playerView.playCallback = {
                guard self.timer == nil else {
                    return
                }
                
                self.timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(self.slide), userInfo: nil, repeats: true)
                
                DispatchQueue.main.async {
                    self.playButton.setTitle("Pause", for: .normal)
                }
            }
            
            playerView.pauseCallback = {
                guard self.timer != nil else {
                    return
                }
                
                self.timer?.invalidate()
                self.timer = nil
                
                DispatchQueue.main.async {
                    self.playButton.setTitle("Play", for: .normal)
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "config") {
            let dst = segue.destination as! SwingConfigViewController
            let target = sender as! UIButton
            
            dst.targetPlayer = target == firstConfig ? first.player! : second.player!
        }
    }
    
    @IBAction func unwinded(segue: UIStoryboardSegue, sender: Any?) {
        let src = segue.source as! SwingConfigViewController
        
        updateFrame([], isFirst: src.targetPlayer == first.player)
    }

    @IBAction func action(_ sender: UIButton) {
        switch sender {
        case firstLoad, secondLoad: load(sender, isFirst: sender == firstLoad)
        case playButton: play()
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
    
    func play() {
        
    }
    
    func moveOneFrame(_ sender: UIButton, isPrev: Bool) {
        
    }
    
    func moveFrame(_ rate: Double) {
        
    }
    
    func updatePlaySlide() {
        DispatchQueue.main.async {
        }
    }
    
    func updateFrame(_ points: [Double], isFirst: Bool) {
        // (isFirst ? firstSwingTime : secondSwingTime) = obj.currentTime()
        
        first.player?.seek(to: CMTime(seconds: 0.002, preferredTimescale: 1))
        second.player?.seek(to: CMTime(seconds: 0.002, preferredTimescale: 1))
        
        (isFirst ? firstHindrance : secondHindrance)?.isHidden = true
        
        if (firstHindrance.isHidden && secondHindrance.isHidden) {
            playControlState(true)
            calculateParameters()
        }
    }
    
    func cancelEdit() {
        view.endEditing(true)
    }
    
    private func playControlState(_ state: Bool) {
        playSlider.isEnabled = state
        playButton.isEnabled = state
        
        prevButton.isEnabled = state
        nextButton.isEnabled = state
    }
    
    private func calculateParameters() {
        
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
