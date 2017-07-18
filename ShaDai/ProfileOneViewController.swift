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
import GLKit

class ProfileOneViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var playerView: PlayerView!
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var playSlider: UISlider!
    
    @IBOutlet weak var loadButton: UIButton!
    
    let deviceSize = UIScreen.main.bounds
    
    let srcView = UIView()
    
    let dstView = UIView()
    
    let vertexView = UIView()
    
    let shape = CAShapeLayer()
    
    let wrapper = CAShapeLayer()
    
    let gradient = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.cancelEdit))
        
        view.addGestureRecognizer(tap)
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
    
    @IBAction func onPrevFrame(_ sender: Any) {
        let item = playerView.player!.currentItem!
        
        if (item.canStepBackward) {
            item.step(byCount: -1)
            updatePlaySlide(item: item)
        }
    }
    
    @IBAction func onNextFrame(_ sender: Any) {
        let item = playerView.player!.currentItem!
        
        if (item.canStepForward) {
            item.step(byCount: 1)
            updatePlaySlide(item: item)
        }
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
            
            DispatchQueue.main.async {
                self.loadButton.isEnabled = false
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
            
            let srcX = self.deviceSize.width / 2
            let srcY = playArea.maxY - 40
            let dstX = self.deviceSize.width / 4 + playArea.maxX / 2
            let dstY = playArea.midY + 40
            let vertexX = (srcX + dstX * 2) / 3
            let vertexY = playArea.minY + 20
            
            self.srcView.frame = CGRect(x: srcX, y: srcY, width: 24, height: 24)
            self.dstView.frame = CGRect(x: dstX, y: dstY, width: 24, height: 24)
            self.vertexView.frame = CGRect(x: vertexX, y: vertexY, width: 24, height: 24)
            
            self.srcView.layer.cornerRadius = 12
            self.srcView.layer.masksToBounds = true
            self.srcView.backgroundColor = UIColor(red: 1, green: 0.5, blue: 0, alpha: 0.35)
            
            self.dstView.layer.cornerRadius = 12
            self.dstView.layer.masksToBounds = true
            self.dstView.backgroundColor = UIColor(red: 0, green: 0.75, blue: 1, alpha: 0.35)
            
            self.vertexView.layer.cornerRadius = 12
            self.vertexView.layer.masksToBounds = true
            self.vertexView.backgroundColor = UIColor(red: 1, green: 0, blue: 1, alpha: 0.35)
            
            let srcMove = UIPanGestureRecognizer(target: self, action: #selector(self.move))
            self.srcView.addGestureRecognizer(srcMove)
            
            let dstMove = UIPanGestureRecognizer(target: self, action: #selector(self.move))
            self.dstView.addGestureRecognizer(dstMove)
            
            let vertexMove = UIPanGestureRecognizer(target: self, action: #selector(self.move))
            self.vertexView.addGestureRecognizer(vertexMove)
            
            self.wrapper.frame = playArea
            self.wrapper.backgroundColor = UIColor.red.cgColor
            self.wrapper.mask = self.shape
            self.wrapper.addSublayer(self.gradient)
            
            self.shape.frame = self.wrapper.frame
            self.shape.lineWidth = 3
            self.shape.fillColor = UIColor(white: 1, alpha: 0.45).cgColor
            
            self.gradient.frame = self.wrapper.frame
            
            self.updatePlaySlide(item: playerItem)
            
            DispatchQueue.main.async {
                self.playerView.layer.addSublayer(self.wrapper)
                self.playerView.addSubview(self.srcView)
                self.playerView.addSubview(self.dstView)
                self.playerView.addSubview(self.vertexView)
                
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
            
            let shapeWrapper = CAShapeLayer()
            let wrapperPath = UIBezierPath()
            
            let shapeLayer = CAShapeLayer()
            let shapePath = UIBezierPath()
            
            let playArea = self.playerView.playerLayer.videoRect
            
            var start = CGPoint(x: self.srcView.center.x - 11.2 - playArea.minX, y: self.srcView.center.y - playArea.maxY)
            var end = CGPoint(x: self.dstView.center.x - 1.5 - playArea.minX, y: self.dstView.center.y - playArea.maxY)
            let vertex = CGPoint(x: self.vertexView.center.x - playArea.minX, y: self.vertexView.center.y - playArea.maxY)
            
            var control = self.controlPoint(start: start, end: end, vertex: vertex)
            
            let ratio = videoSize.width / playArea.width
            
            start.x *= ratio
            start.y *= -ratio
            end.x *= ratio
            end.y *= -ratio
            control.x *= ratio
            control.y *= -ratio
            
            shapeLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
            shapeLayer.fillColor = UIColor.white.cgColor
            shapeLayer.backgroundColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = 0
            
            shapePath.move(to: end)
            shapePath.addQuadCurve(to: start, controlPoint: control)
            
//            (2.75, 0.5, 0.25) * 6
            start.x += CGFloat(16.5 * ratio)
            control.x += CGFloat(5 * ratio)
            control.y -= CGFloat(2.5 * ratio)

            end.x += CGFloat(3 * ratio)
            
            shapePath.addLine(to: start)
            shapePath.addQuadCurve(to: end, controlPoint: control)
            
            shapeLayer.path = shapePath.cgPath
            
            shapeWrapper.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
            shapeWrapper.strokeColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.45).cgColor
            shapeWrapper.fillColor = UIColor.clear.cgColor
            shapeWrapper.backgroundColor = UIColor.clear.cgColor
            shapeWrapper.opacity = 0
            shapeWrapper.lineWidth = 40
            
            shapeWrapper.mask = shapeLayer
            
//            (2.75, 0.5, 0.25) * 3
            start.x -= CGFloat(8.25 * ratio)
            control.x -= CGFloat(2.5 * ratio)
            control.y += CGFloat(1.5 * ratio)
            
            end.x -= CGFloat(1.5 * ratio)
            
            wrapperPath.move(to: end)
            wrapperPath.addQuadCurve(to: start, controlPoint: control)
            
            shapeWrapper.path = wrapperPath.cgPath
            
            let currentTime = CMTimeGetSeconds(self.playerView.player!.currentTime())
            let remainder = CMTimeGetSeconds(composition.duration) - currentTime
            
            let strokeStart = CABasicAnimation(keyPath: "strokeStart")
            strokeStart.fromValue = 1
            strokeStart.toValue = 0
            strokeStart.duration = Swift.min(5, remainder)
            
            let opacity = CABasicAnimation(keyPath: "opacity")
            opacity.fromValue = 1
            opacity.toValue = 1
            opacity.duration = remainder
            
            let group = CAAnimationGroup()
            group.beginTime = AVCoreAnimationBeginTimeAtZero + currentTime
            group.isRemovedOnCompletion = false
            group.duration = remainder
            group.animations = [strokeStart, opacity]
            
            let layerComposition = composer.compose([shapeWrapper], animation: [group])
            
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
                            label = String(format: "File Size: %6.4lf MB => %6.4lf MB", sizePrev / 1048576, sizeDone / 1048576)
                            
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
        
        let playArea = self.playerView.playerLayer.videoRect
        
        var start = CGPoint(x: self.srcView.center.x - 11.2 - playArea.minX, y: self.srcView.center.y - 18 - playArea.maxY)
        var end = CGPoint(x: self.dstView.center.x - 1.5 - playArea.minX, y: self.dstView.center.y - 18 - playArea.maxY)
        var vertex = CGPoint(x: self.vertexView.center.x - playArea.minX, y: self.vertexView.center.y - 18 - playArea.maxY)
        
        start.y *= -1
        end.y *= -1
        vertex.y *= -1
        
        var control = controlPoint(start: start, end: end, vertex: vertex)
        
        start.y *= -1
        end.y *= -1
        vertex.y *= -1
        control.y *= -1
        
        //        gradient.startPoint = CGPoint(x: start.x / playArea.width, y: start.y / playArea.height)
        //        gradient.endPoint = CGPoint(x: start.x / playArea.width + 0.02, y: start.y / playArea.height - 0.02)
        
        path.move(to: end)
        path.addQuadCurve(to: start, controlPoint: control)
        
        //            (2.75, 0.5, 0.25) * 6
        start.x += CGFloat(16.5)
        control.x += CGFloat(5)
        control.y += CGFloat(2.5)
        end.x += CGFloat(3)
        
        path.addLine(to: start)
        path.addQuadCurve(to: end, controlPoint: control)
        
        shape.path = path.cgPath
        
//        let ciContext = CIContext()
//        let filter = CIFilter(name: "CILinearGradient", withInputParameters: [
//            "inputPoint0": CIVector(cgPoint: start),
//            "inputPoint1": CIVector(cgPoint: CGPoint(x: (control.x + start.x * 9) / 10, y: (control.y + start.y * 9) / 10)),
//            "inputColor0": UIColor.clear.ciColor,
//            "inputColor1": UIColor.red.ciColor
//            ])
//        
//        filter?.setDefaults()
//        
//        if let output = filter?.outputImage {
//            
//        }
    }
    
    private func controlPoint(start: CGPoint, end: CGPoint, vertex: CGPoint) -> CGPoint {
        let matrix = matrix_double3x3(columns: (vector3(Double(start.x * start.x), Double(start.x), 1.0), vector3(Double(end.x * end.x), Double(end.x), 1.0), vector3(Double(vertex.x * vertex.x), Double(vertex.x), 1.0)))
        
        let inv = matrix_invert(matrix)
        
        let a_db = Double(start.y) * inv.columns.0.x + Double(end.y) * inv.columns.0.y + Double(vertex.y) * inv.columns.0.z
        let b_db = Double(start.y) * inv.columns.1.x + Double(end.y) * inv.columns.1.y + Double(vertex.y) * inv.columns.1.z
        
        let a = CGFloat(a_db)
        let b = CGFloat(b_db)
        
        let coef_a = 2 * a * start.x + b
        let coef_b = 2 * a * end.x + b
        
        let conX = (coef_a * start.x - coef_b * end.x - start.y + end.y) / ((start.x - end.x) * 2 * a)
        let conY = coef_a * (conX - start.x) + start.y
        
        return CGPoint(x: conX, y: conY)
    }
    
    private func checkAscend(_ points: [CGPoint]) -> Bool {
        assert(points.count == 3)
        
        var x = CGFloat(0)
        do {
            try points.forEach { point in
                if (point.x <= x + 10) {
                    throw NSError.init()
                } else {
                    x = point.x
                }
            }
        } catch {
            return false
        }
        
        if (points[1].y >= points[0].y + 10 || points[1].y >= points[2].y + 10) {
            return false
        }
        return true
    }
    
    func move(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            let xPos = view.center.x + translation.x, yPos = view.center.y + translation.y
            let playArea = playerView.playerLayer.videoRect
            
            if (xPos > playArea.minX + 10 && xPos < playArea.maxX - 10 && yPos > playArea.minY + 10 && yPos < playArea.maxY - 10 ) {
                let target = CGPoint(x: xPos, y: yPos)
                if (view == self.srcView) {
                    if (checkAscend([target, self.vertexView.center, self.dstView.center])) {
                        view.center = CGPoint(x: xPos, y: yPos)
                        reDraw()
                    }
                } else if (view == self.dstView) {
                    if (checkAscend([self.srcView.center, self.vertexView.center, target])) {
                        view.center = CGPoint(x: xPos, y: yPos)
                        reDraw()
                    }
                } else if (view == self.vertexView) {
                    if (checkAscend([self.srcView.center, target, self.dstView.center])) {
                        view.center = CGPoint(x: xPos, y: yPos)
                        reDraw()
                    }
                }
            }
        }
        recognizer.setTranslation(CGPoint(), in: self.view)
    }
    
    func updatePlaySlide(item: AVPlayerItem) {
        DispatchQueue.main.async {
            self.playSlider.value = Float(CMTimeGetSeconds(item.currentTime()) / CMTimeGetSeconds(item.asset.duration))
        }
    }
    
    func cancelEdit() {
        view.endEditing(true)
    }
    
}
