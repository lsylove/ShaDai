//
//  EditorViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 24..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVKit
import AVFoundation

class EditorViewController: UIViewController, HSBColorPickerDelegate {
    
    var url: String?
    
    var fps = 30.0
    
    var frequency = 60.0
    
    var ticks = 0
    
    var player = AVPlayer()
    
    var duration = 0.0
    
    var timer: Timer?
    
    var uiTimer: Timer?
    
    @IBOutlet weak var playerView: PlayerView!
    
    @IBOutlet weak var shapeSegControl: UISegmentedControl!
    
    @IBOutlet weak var speedSegControl: UISegmentedControl!
    
    @IBOutlet weak var colorButton: UIButton!
    
    @IBOutlet weak var undoButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var pauseButton: UIButton!
    
    @IBOutlet weak var prevButton: UIButton!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var finishButton: UIButton!
    
    @IBOutlet weak var playbackButton: UIButton!
    
    @IBOutlet weak var slider: UISlider!
    
    @IBAction func speedSeg(_ sender: UISegmentedControl) {
        player.rate = [1.0, 0.5, 0.25][speedSegControl.selectedSegmentIndex]
    }
    
    @IBAction func action(_ sender: UIButton) {
        switch sender {
        case undoButton: undo()
        case playButton: play()
        case pauseButton: pause()
        case prevButton: stepDown()
        case nextButton: stepUp()
        case startButton: start()
        case finishButton: finish()
        default: print("[debug] button void bind")
        }
    }
    
    @IBAction func slide(_ sender: UISlider) {
        let targetTime = Double(sender.value) * duration
        player.currentItem!.step(byCount: Int(fps * (targetTime - CMTimeGetSeconds(player.currentTime()))))
        
        pause()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let url = URL(fileURLWithPath: self.url!)
        player = AVPlayer(url: url)
        playerView.player = player
        
        player.actionAtItemEnd = .pause
        toggleButtons(playButton, pauseButton)
        toggleButtons(startButton, finishButton)
        
        DispatchQueue.global().async {
            let item = self.player.currentItem!
            while (item.status != .readyToPlay) {
                
            }
            self.duration = CMTimeGetSeconds(self.player.currentItem!.duration)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        pause()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "color") {
            let dst = segue.destination as! ColorPickerViewController
            dst.delegate = self
        }
    }
    
    func HSBColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizerState) {
        for view in [shapeSegControl, colorButton, undoButton] as [UIView] {
            view.tintColor = color
        }
    }
    
    func undo() {
        let frame = CMTimeGetSeconds(player.currentTime()) * fps
        print(frame, Int(round(frame)))
    }
    
    func stepUp() {
        let item = player.currentItem!
        if (item.canStepForward) {
            item.step(byCount: 1)
            pause()
        }
    }
    
    func stepDown() {
        let item = player.currentItem!
        if (item.canStepBackward) {
            item.step(byCount: -1)
            pause()
        }
    }
    
    func play() {
        player.play()
        
        uiTimer = Timer.scheduledTimer(timeInterval: 1.0 / frequency, target: self, selector: #selector(self.uiTick), userInfo: nil, repeats: true)
        
        toggleButtons(playButton, pauseButton, paused: false)
        speedSeg(speedSegControl)
    }
    
    func pause() {
        player.pause()
        
        uiTimer?.invalidate()
        uiTimer = nil
        
        toggleButtons(playButton, pauseButton)
        updateSliderPosition()
    }
    
    func uiTick() {
        DispatchQueue.main.async {
            self.updateSliderPosition()
        }
    }
    
    func tick() {
        ticks += 1
    }
    
    func start() {
        timer = Timer.scheduledTimer(timeInterval: 1.0 / frequency, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        
        toggleButtons(startButton, finishButton, paused: false)
    }
    
    func finish() {
        timer?.invalidate()
        timer = nil
        
        toggleButtons(startButton, finishButton)
    }
    
    private func updateSliderPosition() {
        slider.value = Float(CMTimeGetSeconds(player.currentTime()) / duration)
    }
    
    private func toggleButtons(_ button1: UIButton, _ button2: UIButton, paused: Bool = true) {
        button1.isHidden = !paused
        button2.isHidden = paused
    }

}
