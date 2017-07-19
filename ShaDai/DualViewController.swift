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
    
    var firstSwingTime = CMTime()
    
    var secondSwingTime = CMTime()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        firstConfig.isEnabled = false
        secondConfig.isEnabled = false
        
        playControlState(false)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.cancelEdit))
        view.addGestureRecognizer(tap)
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
        
        updateFrame(src.targetPlayer, isFirst: src.targetPlayer == first.player)
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
    
    func updateFrame(_ obj: AVPlayer, isFirst: Bool) {
        // (isFirst ? firstSwingTime : secondSwingTime) = obj.currentTime()
        if (isFirst) {
            firstSwingTime = obj.currentTime()
        } else {
            secondSwingTime = obj.currentTime()
        }
        
        first.player?.seek(to: CMTime(seconds: 0.002, preferredTimescale: 3))
        second.player?.seek(to: CMTime(seconds: 0.002, preferredTimescale: 3))
        
        (isFirst ? firstHindrance : secondHindrance)?.isHidden = true
        
        if (firstHindrance.isHidden && secondHindrance.isHidden) {
            playControlState(true)
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
    
    private func showMessage(_ message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Message", message: message, preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true)
        }
    }
}
