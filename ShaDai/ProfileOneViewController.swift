//
//  ProfileOneViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 14..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVFoundation
import AVKit
import Photos

class ProfileOneViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var playerView: PlayerView!
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var convexSlider: UISlider!
    
    @IBOutlet weak var playSlider: UISlider!
    
    let deviceSize = UIScreen.main.bounds
    
    let srcView = UIView()
    
    let dstView = UIView()
    
    let shape = CAShapeLayer()
    
    var convexity: CGFloat = 5.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    @IBAction func onLoad(_ sender: Any) {
        loadVideo()
    }
    
    @IBAction func onSave(_ sender: Any) {
        processVideo()
    }
    
    @IBAction func onConvexSlide(_ sender: Any) {
        convexity = CGFloat(7.5 - convexSlider.value * 5.0)
        reDraw()
    }
    
    @IBAction func onPlaySlide(_ sender: Any, forEvent event: UIEvent) {
        DispatchQueue.global().async {
            
            let durationTime = self.playerView.player!.currentItem!.asset.duration
            let duration = CMTimeGetSeconds(durationTime)
            
            var sec = Double(self.playSlider.value) * duration
            var ts = durationTime.timescale
            
            if (sec < 1.002) {
                sec = 0.002
                ts = 3
            } else if (sec > duration - 1.012) {
                sec = duration - 0.012
            }
            
            DispatchQueue.main.async {
                self.playerView.player!.seek(to: CMTimeMakeWithSeconds(sec, ts), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            }
        }
    }
    
    //    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
    //    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
    //    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
    //    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
    
    func loadVideo() {
        DispatchQueue.global().async {
            guard let path = Bundle.main.path(forResource: self.textField.text ?? "nil", ofType: "mp4") else {
                self.showMessage("No such resource file!")
                return
            }
            
            let url = URL(fileURLWithPath: path)
            let (asset, sourceTrack) = self.retrieveAsset(url)
            
            let sizePrev = self.sizeEstimation(sourceTrack)
            self.showMessage(String(format: "File Size: %.4lf MB", sizePrev / 1024 / 1024))
            
            let playerItem = AVPlayerItem(asset: asset)
            self.playerView.player = AVPlayer(playerItem: playerItem)
            
            while (playerItem.status != .readyToPlay) {
                
            }
            
            let playArea = self.playerView.playerLayer.videoRect
            
            let srcX = self.deviceSize.width / 2.0
            let srcY = playArea.maxY - 40
            let dstX = self.deviceSize.width / 4.0 + playArea.maxX / 2.0
            let dstY = playArea.midY + 40
            
            self.srcView.frame = CGRect(x: srcX, y: srcY, width: 24, height: 24)
            self.dstView.frame = CGRect(x: dstX, y: dstY, width: 24, height: 24)
            
            self.srcView.layer.cornerRadius = 12
            self.srcView.layer.masksToBounds = true
            self.srcView.backgroundColor = UIColor.orange
            
            self.dstView.layer.cornerRadius = 12
            self.dstView.layer.masksToBounds = true
            self.dstView.backgroundColor = UIColor.green
            
            let srcMove = UIPanGestureRecognizer(target: self, action: #selector(self.move))
            self.srcView.addGestureRecognizer(srcMove)
            
            let dstMove = UIPanGestureRecognizer(target: self, action: #selector(self.move))
            self.dstView.addGestureRecognizer(dstMove)
            
            self.shape.frame = CGRect(x: 0, y: 0, width: self.deviceSize.width, height: self.deviceSize.height)
            self.shape.fillColor = UIColor.clear.cgColor
            self.shape.strokeColor = UIColor.red.cgColor
            self.shape.strokeStart = 0
            self.shape.strokeEnd = 1
            self.shape.opacity = 0.75
            self.shape.lineWidth = 3
            
            DispatchQueue.main.async {
                self.playerView.layer.addSublayer(self.shape)
                self.playerView.addSubview(self.srcView)
                self.playerView.addSubview(self.dstView)
                
                self.reDraw()
            }
        }
    }
    
    func processVideo() {
        DispatchQueue.global().async {
            
            guard let asset = self.playerView.player?.currentItem!.asset else {
                self.showMessage("Nothing loaded yet!")
                return
            }
            let sourceTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first!
            
            let composition = self.loadAndInsertTrack(sourceTrack)
            
            let videoSize = composition.naturalSize
            let composer = AVAnimationComposer(composition)
            
            let shapeLayer = Array(repeating: CAShapeLayer(), count: 7)
            let shapePath = UIBezierPath()
            
            var startPoint = CGPoint(x: 25, y: 25)
            let endPoint = CGPoint(x: 255, y: 65)
            var control = CGPoint(x: 240, y: 350)
            
            for shape in shapeLayer {
                shape.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
                shape.fillColor = UIColor(white: 1, alpha: 0).cgColor
                shape.strokeColor = UIColor.yellow.cgColor
                shape.strokeStart = 0
                shape.strokeEnd = 1
                shape.opacity = 0
                shape.lineWidth = 3
                
                startPoint.x += CGFloat(2.75)
                control.x += CGFloat(0.5)
                control.y += CGFloat(0.25)
                
                shapePath.removeAllPoints()
                shapePath.move(to: endPoint)
                shapePath.addQuadCurve(to: startPoint, controlPoint: control)
                
                shape.path = shapePath.cgPath.copy()!
            }
            
            let strokeStart = CABasicAnimation(keyPath: "strokeStart")
            strokeStart.fromValue = 1
            strokeStart.toValue = 0
            strokeStart.duration = 1
            
            let opacity = CABasicAnimation(keyPath: "opacity")
            opacity.fromValue = 1
            opacity.toValue = 1
            opacity.duration = CMTimeGetSeconds(composition.duration) - 2
            
            let group = CAAnimationGroup()
            group.beginTime = AVCoreAnimationBeginTimeAtZero + 2
            group.isRemovedOnCompletion = false
            group.duration = CMTimeGetSeconds(composition.duration) - 2
            group.animations = [strokeStart, opacity]
            
            var animations: [CAAnimation] = [group]
            for _ in 1..<shapeLayer.count {
                animations.append(group.copy() as! CAAnimation)
            }
            
            let layerComposition = composer.compose(shapeLayer, animation: animations)
            
            let snapshot: AVComposition = composition.copy() as! AVComposition
            
            guard let (reader, readMaterial) = self.prepareReader(snapshot) else {
                self.showMessage("Resource input preparation failure!")
                return
            }
            readMaterial.videoComposition = layerComposition
            reader.startReading()
            
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                self.showMessage("Temp directory read failure!")
                return
            }
            
            let tempURL = dir.appendingPathComponent("temp.mp4")
            try? FileManager.default.removeItem(at: tempURL)
            
            guard let (writer, writeMaterial) = self.prepareWriter(tempURL, size: snapshot.naturalSize) else {
                self.showMessage("Resource output preparation failure!")
                return
            }
            writer.startWriting()
            writer.startSession(atSourceTime: kCMTimeZero)
            
            self.showMessage("Compressing...")
            self.syncBufferIO(readMaterial: readMaterial, writeMaterial: writeMaterial) {
                writer.endSession(atSourceTime: asset.duration)
                writer.finishWriting {
                    guard writer.status == .completed else {
                        self.showMessage("Write to buffer failure!")
                        try? FileManager.default.removeItem(at: tempURL)
                        return
                    }
                    
                    self.showMessage("Writing to file...")
                    self.submitToCameraRoll(tempURL) { saved in
                        var strn: String
                        var label: String
                        if saved {
                            strn = "Success"
                            let (_, track) = self.retrieveAsset(tempURL)
                            let sizePrev = self.sizeEstimation(sourceTrack)
                            let sizeDone = self.sizeEstimation(track)
                            label = String(format: "File Size: %.4lf MB => %.4lf MB", sizePrev / 1048576, sizeDone / 1048576)
                            
                        } else {
                            strn = "Failed"
                            label = "File Save Failure"
                        }
                        DispatchQueue.main.async {
                            self.label.text = label
                            
                            let alertController = UIAlertController(title: strn, message: nil, preferredStyle: .alert)
                            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(defaultAction)
                            self.present(alertController, animated: true)
                        }
                        
                    }
                }
            }
        }
    }
    
//    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
//    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
//    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
//    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
    
    private func showMessage(_ message: String) -> Void {
        DispatchQueue.main.async {
            self.label.text = message
        }
    }
    
    private func sizeEstimation(_ track: AVAssetTrack) -> Double {
        let ratePrev = track.estimatedDataRate / 8
        let secPrev = CMTimeGetSeconds(track.timeRange.duration)
        
        return Double(ratePrev) * secPrev
    }
    
    private func retrieveAsset(_ url: URL) -> (AVAsset, AVAssetTrack) {
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
        let sourceTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first!
        return (asset, sourceTrack)
    }
    
    private func loadAndInsertTrack(_ track: AVAssetTrack) -> AVMutableComposition {
        let composition = AVMutableComposition()
        let compoTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        try! compoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, track.asset!.duration), of: track, at: kCMTimeZero)
        compoTrack.preferredTransform = track.preferredTransform
        
        return composition
    }
    
    private func prepareReader(_ asset: AVAsset) -> (AVAssetReader, AVAssetReaderVideoCompositionOutput)? {
        guard let reader = try? AVAssetReader(asset: asset) else {
            return nil
        }
        
        let readTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first!
        let readMaterial = AVAssetReaderVideoCompositionOutput(videoTracks: [readTrack], videoSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ])
        guard reader.canAdd(readMaterial) else {
            return nil
        }
        reader.add(readMaterial)
        return (reader, readMaterial)
    }
    
    private func prepareWriter(_ url: URL, size: CGSize) -> (AVAssetWriter, AVAssetWriterInput)? {
        guard let writer = try? AVAssetWriter(outputURL: url, fileType: AVFileTypeQuickTimeMovie) else {
            return nil
        }
        
        let writeMaterial = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8 * 65536,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264Main31,
                AVVideoMaxKeyFrameIntervalKey: 8
            ]])
        guard writer.canAdd(writeMaterial) else {
            return nil
        }
        writer.add(writeMaterial)
        return (writer, writeMaterial)
    }
    
    private func syncBufferIO(readMaterial: AVAssetReaderOutput, writeMaterial: AVAssetWriterInput, callback: () -> Void) {
        let serialQueue = DispatchQueue(label: "serial")
        let group = DispatchGroup()
        
        group.enter()
        writeMaterial.requestMediaDataWhenReady(on: serialQueue) {
            while (writeMaterial.isReadyForMoreMediaData) {
                if let nextBuffer = readMaterial.copyNextSampleBuffer() {
                    writeMaterial.append(nextBuffer)
                } else {
                    writeMaterial.markAsFinished()
                    group.leave()
                    break
                }
            }
        }
        
        group.wait()
        callback()
    }
    
    private func submitToCameraRoll(_ url: URL, callback: @escaping (_ saved: Bool) -> Void) -> Void {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            callback(saved)
        }
    }
    
    //    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
    //    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
    //    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
    //    akakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakakak
    
    private func reDraw() {
        let path = UIBezierPath()
        
        //        Swift.max(src.center.y, dst.center.y)
        let conX = (srcView.center.x + dstView.center.x * 9) / 10
        let conY = Swift.min(srcView.center.y, dstView.center.y) + Swift.abs(srcView.center.x - dstView.center.x) * convexity - deviceSize.height
        
        var start = CGPoint(x: srcView.center.x - 9.7, y: srcView.center.y)
        let end = CGPoint(x: dstView.center.x, y: dstView.center.y)
        var control = CGPoint(x: conX, y: conY)
        
        for _ in 0..<7 {
            path.move(to: end)
            path.addQuadCurve(to: start, controlPoint: control)
            
            start.x += 2.75
            control.x += 0.5
            control.y += 0.25
        }
        
        shape.path = path.cgPath
    }
    
    func move(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            let xPos = view.center.x + translation.x, yPos = view.center.y + translation.y
            
            if (xPos > 20 && xPos < self.deviceSize.width - 20 && yPos > 100 && yPos < self.deviceSize.height - 150) {
                view.center = CGPoint(x: xPos, y: yPos)
                reDraw()
            }
        }
        recognizer.setTranslation(CGPoint(), in: self.view)
    }

}
