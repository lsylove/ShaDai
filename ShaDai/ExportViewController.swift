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
            let str = self.textField.text ?? "nil"
            guard let path = Bundle.main.path(forResource: str, ofType: "mp4") else {
                DispatchQueue.main.async {
                    self.label.text = "No such resource file!"
                }
                return
            }
            
            let url = URL(fileURLWithPath: path)
            let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
            let sourceTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first!
            
            let ratePrev = sourceTrack.estimatedDataRate / 8
            let secPrev = CMTimeGetSeconds(sourceTrack.timeRange.duration)
            
            let sizePrev = Double(ratePrev) * secPrev
            DispatchQueue.main.async {
                self.label.text = String(format: "File Size: %.4lf MB => ", sizePrev / 1024 / 1024)
            }
            
            let composition = AVMutableComposition()
            let compoTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            try! compoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: sourceTrack, at: kCMTimeZero)
            compoTrack.preferredTransform = sourceTrack.preferredTransform
            
            //        Do your editing
            
            let snapshot: AVComposition = composition.copy() as! AVComposition
            guard let reader = try? AVAssetReader(asset: snapshot) else {
                DispatchQueue.main.async {
                    self.label.text = "Resource snapshot failure!"
                }
                return
            }
            
            let readTrack = snapshot.tracks(withMediaType: AVMediaTypeVideo).first!
            let readMaterial = AVAssetReaderTrackOutput(track: readTrack, outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
                ])
            guard reader.canAdd(readMaterial) else {
                DispatchQueue.main.async {
                    self.label.text = "Resource input material failure!"
                }
                return
            }
            reader.add(readMaterial)
            reader.startReading()
            
            guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                DispatchQueue.main.async {
                    self.label.text = "Temp directory read failure!"
                }
                return            }
            
            let tempURL = dir.appendingPathComponent("temp.mp4")
            try? FileManager.default.removeItem(at: tempURL)
            
            guard let writer = try? AVAssetWriter(outputURL: tempURL, fileType: AVFileTypeQuickTimeMovie) else {
                DispatchQueue.main.async {
                    self.label.text = "Resource output path failure!"
                }
                return
            }
            
            let writeMaterial = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: [
                AVVideoCodecKey: AVVideoCodecH264,
                AVVideoWidthKey: Int(sourceTrack.naturalSize.width),
                AVVideoHeightKey: Int(sourceTrack.naturalSize.height),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 8 * 65536,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264Main31,
                    AVVideoMaxKeyFrameIntervalKey: 8
                ]])
            guard writer.canAdd(writeMaterial) else {
                DispatchQueue.main.async {
                    self.label.text = "Resource output material failure!"
                }
                return
            }
            writer.add(writeMaterial)
            writer.startWriting()
            writer.startSession(atSourceTime: kCMTimeZero)
            
            DispatchQueue.main.async {
                self.label.text = "Writing to temporary buffer..."
            }
            
            let serialQueue = DispatchQueue(label: "serial")
            let semaphore = DispatchSemaphore(value: 0)
            
            writeMaterial.requestMediaDataWhenReady(on: serialQueue) {
                while (writeMaterial.isReadyForMoreMediaData) {
                    if let nextBuffer = readMaterial.copyNextSampleBuffer() {
                        writeMaterial.append(nextBuffer)
                    } else {
                        writeMaterial.markAsFinished()
                        semaphore.signal()
                        break
                    }
                }
            }
            
            semaphore.wait()
            
            writer.endSession(atSourceTime: asset.duration)
            writer.finishWriting {
                
                guard writer.status == .completed else {
                    DispatchQueue.main.async {
                        self.label.text = "Write to buffer failure!"
                    }
                    try? FileManager.default.removeItem(at: tempURL)
                    return
                }
                
                let tempAsset = AVURLAsset(url: tempURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
                DispatchQueue.main.async {
                    self.label.text = "Writing to file..."
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
                }) { saved, error in
                    var strn: String
                    var label: String
                    if saved {
                        strn = "Success"
                        let tempTrack = tempAsset.tracks(withMediaType: AVMediaTypeVideo).first!
                        
                        let rateDone = tempTrack.estimatedDataRate / 8
                        let secDone = CMTimeGetSeconds(tempTrack.timeRange.duration)
                        
                        let sizeDone = Double(rateDone) * secDone
                        label = String(format: "File Size: %.4lf MB => %.4lf MB", sizePrev / 1024 / 1024, sizeDone / 1024 / 1024)
                        
                    } else {
                        strn = "Failed"
                        label = "File Save Failure"
                    }
                    DispatchQueue.main.async {
                        self.label.text = label
                        let alertController = UIAlertController(title: strn, message: nil, preferredStyle: .alert)
                        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertController.addAction(defaultAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                    
                    try? FileManager.default.removeItem(at: tempURL)
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

}
