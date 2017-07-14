//
//  ExportViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 10..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Photos

class ExportViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var playerView: PlayerView!
    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onLoad(_ sender: Any) {
        processVideo()
        playerView.play()
    }
    
    @IBAction func onPlay(_ sender: Any) {
        playerView.toggle()
    }
    
    func processVideo() {
        DispatchQueue.global().async {
            guard let path = Bundle.main.path(forResource: self.textField.text ?? "nil", ofType: "mp4") else {
                self.showMessage("No such resource file!")
                return
            }
            
            let url = URL(fileURLWithPath: path)
            let (asset, sourceTrack) = self.retrieveAsset(url)
            
            let sizePrev = self.sizeEstimation(sourceTrack)
            self.showMessage(String(format: "File Size: %.4lf MB => ", sizePrev / 1024 / 1024))
            
            let composition = self.loadAndInsertTrack(sourceTrack)
            
            //        Do your editing
            
//            let composer = AVAnimationComposer(composition)
//            let layerComposition = composer.compose(composer.textObject("Hello Golfzon")) { composition in
//                let videoSize = composition.naturalSize
//                let animation = CABasicAnimation(keyPath: "position")
//                animation.beginTime = AVCoreAnimationBeginTimeAtZero
//                animation.isRemovedOnCompletion = false
//                animation.isAdditive = false
//                animation.fromValue = NSValue(cgPoint: CGPoint(x: videoSize.width / 4, y: videoSize.height / 12 * 11))
//                animation.toValue = NSValue(cgPoint: CGPoint(x: videoSize.width / 4 * 3, y: videoSize.height / 12 * 11))
//                animation.duration = CMTimeGetSeconds(composition.duration)
//                return animation
//            }
            
            let videoSize = composition.naturalSize
            let composer = AVAnimationComposer(composition)
            
            let shapeLayer = [CAShapeLayer(), CAShapeLayer(), CAShapeLayer(), CAShapeLayer(), CAShapeLayer(), CAShapeLayer(), CAShapeLayer(), CAShapeLayer(), CAShapeLayer()]
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
            
            //        Editing done
            
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
                            let sizeDone = self.sizeEstimation(track)
                            label = String(format: "File Size: %.4lf MB => %.4lf MB", sizePrev / 1048576, sizeDone / 1048576)
                            
                        } else {
                            strn = "Failed"
                            label = "File Save Failure"
                        }
                        DispatchQueue.main.async {
                            self.label.text = label
                            
                            let alertController = UIAlertController(title: strn, message: nil, preferredStyle: .alert)
                            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: {
                                
                                _ in
                            
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { 

                                    let avpc = AVPlayerViewController()
                                    avpc.player = AVPlayer(url: tempURL)
                                    self.present(avpc, animated: true)
                                    try! FileManager.default.removeItem(at: tempURL)
                                })
                            })
                            alertController.addAction(defaultAction)
                            self.present(alertController, animated: true)
                        }
                        
                    }
                }
            }
        }
    }
    
    func exportVideo() {
        DispatchQueue.global().async {
            guard let path = Bundle.main.path(forResource: self.textField.text ?? "nil", ofType: "mp4") else {
                self.showMessage("No such resource file!")
                return
            }
        
            let url = URL(fileURLWithPath: path)
            self.submitToCameraRoll(url) { saved in
                if saved {
                    self.showMessage("saved")
                } else {
                    self.showMessage("not saved")
                }
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
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
}
