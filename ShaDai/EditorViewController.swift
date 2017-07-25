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
    
    private var fps = 30.0
    
    private var frequency = 60.0
    
    private var player = AVPlayer()
    
    private var duration = 0.0
    
    private var rate: Float = 1.0
    
    private var timer: Timer?
    
    private var recordSession: RecordSession?
    
    private var cycle = 2
    
    private var ccount = 0
    
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
        updateSpeed()
        
        if (player.timeControlStatus == .playing) {
            player.rate = rate
        }
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
        case playbackButton: playback()
        default: print("[debug] button void bind")
        }
    }
    
    @IBAction func slide(_ sender: UISlider) {
        let targetTime = Double(sender.value) * duration
        let steps = Int(fps * (targetTime - CMTimeGetSeconds(player.currentTime())))
        
        recordSession?.record(entity: PlaybackEvent(steps))
        player.currentItem!.step(byCount: steps)
        
        suspend()
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
            recordSession?.record(entity: FrameEvent.forward)
            item.step(byCount: 1)
            
            suspend()
        }
    }
    
    func stepDown() {
        let item = player.currentItem!
        
        if (item.canStepBackward) {
            recordSession?.record(entity: FrameEvent.backward)
            item.step(byCount: -1)
            
            suspend()
        }
    }
    
    func play() {
//        recordSession?.record(entity: PlayEvent.play)
        player.playImmediately(atRate: rate)
        
        timer = Timer.scheduledTimer(timeInterval: 1.0 / frequency, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        
        toggleButtons(playButton, pauseButton, paused: false)
    }
    
    func pause() {
//        recordSession?.record(entity: PlayEvent.pause)
        player.pause()
        
        timer?.invalidate()
        timer = nil
        
        toggleButtons(playButton, pauseButton)
        updateSliderPosition()
    }
    
    private func suspend() {
        ccount = 0
        
        player.pause()
        
        timer?.invalidate()
        timer = nil
        
        toggleButtons(playButton, pauseButton)
        updateSliderPosition()
    }
    
    func tick() {
        ccount += 1
        if (ccount % cycle == 0) {
            recordSession?.record(entity: FrameEvent.forward)
        }
        
        DispatchQueue.main.async {
            self.updateSliderPosition()
        }
    }
    
    func start() {
        suspend()
        
        recordSession = RecordSession(frequency: frequency)
        
        // Save initial state as events
        recordSession!.record(entity: SeekEvent(player.currentTime()))
        updateSpeed()
        
        toggleButtons(startButton, finishButton, paused: false)
        playbackButton.isEnabled = false
    }
    
    func finish() {
        if !(recordSession?.deactivateSession() ?? false) {
            print("[debug] record session poor termination")
        }
        
        toggleButtons(startButton, finishButton)
        playbackButton.isEnabled = true
    }
    
    func playback() {
        if let s = recordSession {
            if !s.active {
                suspend()
                let controls: [UIControl] = [playbackButton, startButton, playButton, colorButton, undoButton, prevButton, nextButton, slider, shapeSegControl, speedSegControl]
                
                controls.forEach { $0.isEnabled = false }
                
                timer = Timer.scheduledTimer(timeInterval: 1.0 / frequency, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
                
                
                s.execute(player: player) {
                    self.timer?.invalidate()
                    self.timer = nil
                    
                    controls.forEach { $0.isEnabled = true }
                }
            }
        }
    }
    
    private func updateSpeed() {
        let index = speedSegControl.selectedSegmentIndex
        rate = Float([1.0, 0.5, 0.25][index])
        
        recordSession?.record(entity: RateEvent(rate))
        recordSession?.record(entity: ArbitraryEvent { _,_,_ in self.speedSegControl.selectedSegmentIndex = index })
        
        // Bad coding practice: update cycle
        cycle = Int(round(2.0 / rate))
    }
    
    private func updateSliderPosition() {
        slider.value = Float(CMTimeGetSeconds(player.currentTime()) / duration)
    }
    
    private func toggleButtons(_ button1: UIButton, _ button2: UIButton, paused: Bool = true) {
        button1.isHidden = !paused
        button2.isHidden = paused
    }

}
