//
//  EditorViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 24..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVKit
import AVFoundation
import Photos

class EditorViewController: UIViewController {
    
    var url: String?
    
    private let fps = 30.0
    
    private let frequency = 60.0
    
    //
    
    private var player = AVPlayer()
    
    private var duration = 0.0
    
    private var rate: Float = 1.0
    
    private var videoFrame = CGRect()
    
    //
    
    fileprivate var timer: Timer?
    
    fileprivate var recordSession: RecordSession?
    
    //
    
    private var cycle = 2
    
    private var ccount = 0
    
    //
    
    fileprivate var shapes = [ShapeView]()
    
    fileprivate var current: ShapeView?
    
    private var previous = [ShapeView : ShapeView]()
    
    private var inter = [ShapeView]()
    
    //
    
    private var audioRecorder: AVAudioRecorder?
    
    private let audioSettings = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    private lazy var audioURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("temp.wav")
    }()
    
    //
    
    @IBOutlet weak var playerView: PlayerView!
    
    @IBOutlet weak var colorView: UIView!
    
    @IBOutlet weak var shapeSeg: UISegmentedControl!
    
    @IBOutlet weak var speedSeg: UISegmentedControl!
    
    @IBOutlet weak var colorButton: UIButton!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var pauseButton: UIButton!
    
    @IBOutlet weak var prevButton: UIButton!
    
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var finishButton: UIButton!
    
    @IBOutlet weak var playbackButton: UIButton!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var maskView: UIView!
    
    // >_<
    
    @IBAction func speedChange(_ sender: UISegmentedControl) {
        updateSpeed()
        
        if (player.timeControlStatus == .playing) {
            player.rate = rate
        }
    }
    
    func shapeChange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
            self.appendShape()
            
            let index = self.shapeSeg.selectedSegmentIndex
            //        recordSession?.record(entity: ArbitraryEvent { [weak self] _,_,_ in self?.shapeSeg.selectedSegmentIndex = index })
            self.recordSession?.record(entity: SegmentedControlEvent(self.shapeSeg, index))
        }
    }
    
    // >_<
    
    @IBAction func action(_ sender: UIButton) {
        switch sender {
        case deleteButton: delete()
        case playButton: play()
        case pauseButton: pause()
        case prevButton: stepDown()
        case nextButton: stepUp()
        case startButton: start()
        case finishButton: finish()
        case playbackButton: playback()
        case saveButton: save()
        default: assert(false, "[debug] button void bind")
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
        
        playerView.backgroundColor = .clear
        
        player.actionAtItemEnd = .pause
        toggleButtons(playButton, pauseButton)
        toggleButtons(startButton, finishButton)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.pickShape)))
        
        let segTap = UITapGestureRecognizer(target: self, action: #selector(self.shapeChange))
        segTap.cancelsTouchesInView = false
        shapeSeg.addGestureRecognizer(segTap)
        
        colorView.layer.borderColor = UIColor.black.cgColor
        colorView.layer.borderWidth = 1
        
        DispatchQueue.global().async {
            let item = self.player.currentItem!
            while (item.status != .readyToPlay) {
                
            }
            
            self.duration = CMTimeGetSeconds(self.player.currentItem!.duration)
            
//            let outer = self.playerView.frame
//            let inner = self.playerView.playerLayer.videoRect
//            
//            let translatedOrigin = CGPoint(x: outer.minX + inner.minX, y: outer.minY + inner.minY)
//            self.videoFrame = CGRect(origin: translatedOrigin, size: inner.size)
            self.videoFrame = self.playerView.playerLayer.videoRect
            
            self.maskView.frame = self.playerView.frame
            self.maskView.bounds = self.videoFrame
        }
        
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try! session.setActive(true)
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
    
    // >_<
    
    func delete() {
        if let current = current {
            removeShape(current)
        }
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
        // recordSession?.record(entity: PlayEvent.play)
        player.playImmediately(atRate: rate)
        
        timer = Timer.scheduledTimer(timeInterval: 1.0 / frequency, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        
        toggleButtons(playButton, pauseButton, paused: false)
    }
    
    func pause() {
        // recordSession?.record(entity: PlayEvent.pause)
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
        
        previous.removeAll()
        zip(shapes, shapes.map{ $0.copy() as! ShapeView }).forEach { previous[$0.0] = $0.1 }
        
        recordSession = RecordSession(frequency: frequency)
        recordSession!.delegate = self
        
        // Save initial state as events
        recordSession!.record(entity: SeekEvent(player.currentTime()))
        recordSession!.record(entity: RateEvent(rate))
        recordSession!.record(entity: SegmentedControlEvent(speedSeg, speedSeg.selectedSegmentIndex))
        recordSession!.record(entity: SegmentedControlEvent(shapeSeg, shapeSeg.selectedSegmentIndex))
        
        let color = colorView.backgroundColor
        recordSession!.record(entity: ArbitraryEvent { [weak self] _,_,_ in self?.colorView.backgroundColor = color })
        
        toggleButtons(startButton, finishButton, paused: false)
        playbackButton.isEnabled = false
        saveButton.isEnabled = false
        
        if audioRecorder?.isRecording ?? false {
            audioRecorder?.stop()
            audioRecorder = nil
            print("[debug] audio recorder state corruption")
            
        } else if let audioRecorder = try? AVAudioRecorder(url: audioURL, settings: audioSettings) {
            audioRecorder.record()
            self.audioRecorder = audioRecorder
            
        } else {
            print("[debug] OMG not recording")
        }
    }
    
    func finish() {
        recordSession?.record(entity: VoidEvent())
        
        if !(recordSession?.deactivateSession() ?? false) {
            print("[debug] record session poor termination")
        }
        
        inter = shapes
        
        toggleButtons(startButton, finishButton)
        playbackButton.isEnabled = true
        saveButton.isEnabled = true
        
        if audioRecorder?.isRecording ?? false {
            audioRecorder?.stop()
            audioRecorder = nil
            
            let asset = AVURLAsset(url: audioURL)
            recordSession?.assets = [asset]
            
        } else {
            print("[debug] audio recorder state corruption while finishing")
        }
    }
    
    func playback() {
        if let s = recordSession {
            if !s.active {
                suspend()
                var futureSnapshot: [ShapeView: ShapeView] = [:]
                zip(shapes, shapes.map{ $0.copy() as! ShapeView }).forEach { futureSnapshot[$0.0] = $0.1 }
                
                for shape in shapes + inter {
                    returnShapeToOriginalPosition(shape)
                    shape.removeFromSuperview()
                }
                for (curr, prev) in previous {
                    curr.absA = prev.absA
                    curr.absB = prev.absB
                    curr.c = prev.c
                    
                    if (prev.isSelected) {
                        curr.isSelected = true
                    } else {
                        curr.isSelected = false
                    }
                    
                    playerView.addSubview(curr)
                    curr.setNeedsDisplay()
                }
                
                let controls: [UIControl] = [playbackButton, startButton, playButton, colorButton, deleteButton, prevButton, nextButton, saveButton, slider, shapeSeg, speedSeg]
                
                controls.forEach { $0.isEnabled = false }
                
                timer = Timer.scheduledTimer(timeInterval: 1.0 / frequency, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
                
                s.execute(playerView: playerView, superView: self.view) {
                    self.timer?.invalidate()
                    self.timer = nil
                    
                    controls.forEach { $0.isEnabled = true }
                    
                    for shape in self.inter {
                        self.returnShapeToOriginalPosition(shape)
                        shape.removeFromSuperview()
                    }
                    for (curr, future) in futureSnapshot {
                        curr.absA = future.absA
                        curr.absB = future.absB
                        curr.c = future.c
                        
                        if (future.isSelected) {
                            self.selectShape(curr)
                        }
                        
                        self.playerView.addSubview(curr)
                        curr.setNeedsDisplay()
                    }
                }
            }
        }
    }
    
    func save() {
        if let s = recordSession {
            if !s.active {
                suspend()
                
                progressView.isHidden = false
                maskView.isHidden = false
                
                var futureSnapshot: [ShapeView: ShapeView] = [:]
                zip(shapes, shapes.map{ $0.copy() as! ShapeView }).forEach { futureSnapshot[$0.0] = $0.1 }
                
                for shape in shapes + inter {
                    returnShapeToOriginalPosition(shape)
                    shape.removeFromSuperview()
                }
                for (curr, prev) in previous {
                    curr.absA = prev.absA
                    curr.absB = prev.absB
                    curr.c = prev.c
                    
                    if (prev.isSelected) {
                        curr.isSelected = true
                    }
                    
                    playerView.addSubview(curr)
                    curr.setNeedsDisplay()
                }
                
                let controls: [UIControl] = [playbackButton, startButton, playButton, colorButton, deleteButton, prevButton, nextButton, saveButton, slider, shapeSeg, speedSeg]
                
                controls.forEach { $0.isEnabled = false }
                
                timer = Timer.scheduledTimer(timeInterval: 1.0 / frequency, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
                
                let docPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                let url = docPaths[0].appendingPathComponent("recording.mp4")
                
                try? FileManager.default.removeItem(at: url)
                
                print(url)
                
                s.exportAsFile(playerView: playerView, view: playerView, fileURL: url) {
                    
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        
                    }) { saved, error in
                        DispatchQueue.main.async {
                            
                            self.timer?.invalidate()
                            self.timer = nil
                            
                            controls.forEach { $0.isEnabled = true }
                            
                            for shape in self.inter {
                                self.returnShapeToOriginalPosition(shape)
                                shape.removeFromSuperview()
                            }
                            for (curr, future) in futureSnapshot {
                                curr.absA = future.absA
                                curr.absB = future.absB
                                curr.c = future.c
                                
                                if (future.isSelected) {
                                    self.selectShape(curr)
                                }
                                
                                self.playerView.addSubview(curr)
                                curr.setNeedsDisplay()
                            }
                            
                            self.maskView.isHidden = true
                            self.progressView.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    // >_<
    
    @objc private func pickShape(recognizer: UITapGestureRecognizer) {
        if (recognizer.state != .ended) {
            return
        }
        
        let point = recognizer.location(in: playerView)
        let current = self.current
        clearCurrentSelection()
        
        if (current?.frame.contains(point) ?? false) {
            var checkup = current == nil
            for shape in shapes.reversed() {
                if (!shape.frame.contains(point)) {
                    continue
                }
                if (shape == current) {
                    checkup = true
                    continue
                }
                if (!checkup) {
                    continue
                }
                selectShape(shape)
                return
            }
            for shape in shapes.reversed() {
                if (!shape.frame.contains(point)) {
                    continue
                }
                if (shape == current) {
                    return
                }
                selectShape(shape)
                return
            }
            assert(false, "[debug] two iterations should have at least two identical ones!! (even when it's worst)")
            
        } else {
            for shape in shapes.reversed() {
                if (!shape.frame.contains(point)) {
                    continue
                }
                selectShape(shape)
                return
            }
        }
    }
    
    private func selectShape(_ shape: ShapeView) {
        DispatchQueue.main.async {
            shape.isSelected = true
            self.current = shape
            self.recordSession?.record(entity: ShapeRelatedEvent(shape) { shape, _, _, _ in shape.isSelected = true })
            
            shape.removeFromSuperview()
            self.playerView.addSubview(shape)
        }
    }
    
    private func clearCurrentSelection() {
        DispatchQueue.main.async {
            if let current = self.current {
                current.isSelected = false
                self.recordSession?.record(entity: ShapeRelatedEvent(current) { shape, _, _, _ in shape.isSelected = false })
            }
            
            self.current = nil
        }
    }
    
    private func appendShape() {
        let a = CGPoint(x: playerView.bounds.midX, y: playerView.bounds.midY)
        let b = CGPoint(x: a.x + 50, y: a.y + 50)
        let c = colorView.backgroundColor!
        
        let shape = Shape(rawValue: shapeSeg.selectedSegmentIndex)!
        let view = ShapeView(a: a, b: b, c: c, f: videoFrame, d: shape.recipe())
        
        view.delegate = self
        
        shapes.append(view)
        recordSession?.record(entity: ShapeRelatedEvent(view, playerView) { shape, _, view, _ in
            view.addSubview(shape); shape.c = c })
        
        clearCurrentSelection()
        selectShape(view)
    }
    
    private func removeShape(_ target: ShapeView) {
        if (target == current) {
            current = nil
        }
        target.removeFromSuperview()
        recordSession?.record(entity: ShapeRelatedEvent(target) { shape, _, _, _ in shape.removeFromSuperview() })
        
        for (index, shape) in shapes.enumerated() {
            if (shape == target) {
                shapes.remove(at: index)
                
                return
            }
        }
        assert(false, "[debug] should have target shape!!")
    }
    
    private func returnShapeToOriginalPosition(_ shape: ShapeView) {
        let a = CGPoint(x: playerView.bounds.midX, y: playerView.bounds.midY)
        let b = CGPoint(x: a.x + 50, y: a.y + 50)
        
        shape.absA = a
        shape.absB = b
        
        shape.isSelected = false
    }
    
    // >_<
    
    private func updateSpeed() {
        let index = speedSeg.selectedSegmentIndex
        rate = Float([1.0, 0.5, 0.25][index])
        
        recordSession?.record(entity: RateEvent(rate))
        recordSession?.record(entity: SegmentedControlEvent(speedSeg, index))
        
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

extension EditorViewController: HSBColorPickerDelegate {
    
    func HSBColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizerState) {
        colorView.backgroundColor = color
        recordSession?.record(entity: ArbitraryEvent { [weak self] _,_,_ in self?.colorView.backgroundColor = color })
        
        if let current = current {
            current.c = color
            recordSession?.record(entity: ShapeRelatedEvent(current) { shape, _, _, _ in shape.c = color })
        }
    }
    
}

extension EditorViewController: ShapeViewGestureRecognitionDelegate {
    
    func shapeViewGestureRecognition(_ view: ShapeView, recognizer: UIGestureRecognizer, operation: Any) {
        if let recognizer = recognizer as? UIPanGestureRecognizer,
            let operation = operation as? (ShapeView, CGPoint) -> Void {
            
            recordSession?.record(entity: PanningEvent(view, recognizer.translation(in: view), operation: operation))
        }
    }
    
}

extension EditorViewController: ProgressReporterDelegate {
    
    func reportProgress(reporter: ProgressReporter, progress: Double, count: Int?) {
        DispatchQueue.main.async {
            self.progressView.progress = Float(progress)
        }
    }
    
}
