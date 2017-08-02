//
//  RecordExportSession.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 28..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVFoundation
import AVKit

protocol RecordExportSessionDelegate: class {
    func appendingDone(session: RecordExportSession, buffer: CVPixelBuffer, time: CMTime, progress: Double)
}

class RecordExportSession {
    
    private let renderer = ImageRenderer()
    
    private let writer: AVAssetWriter
    
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    
    private let duration: CMTime
    
    private var pixels = [(CVPixelBuffer, CMTime)]()
    
    private let serial = DispatchQueue(label: "serial")
    
    private let worker = DispatchQueue(label: "worker")
    
    private var workerBarrier: DispatchSemaphore? = DispatchSemaphore(value: 0)
    
    private var assetExportDoneFlag = false
    
    private var marked = false
    
    private var appendingCount = 0
    
    private let appenderQueue = DispatchQueue(label: "appender")
    
    var delegate: RecordExportSessionDelegate?
    
    init?(fileURL: URL, size: CGSize, duration: CMTime, asset: AVAsset? = nil) {
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 16 * 65536,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264Main31,
                AVVideoMaxKeyFrameIntervalKey: 8
            ]]
        
        let videoSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        guard let writer = try? AVAssetWriter(outputURL: fileURL, fileType: AVFileTypeQuickTimeMovie) else {
            return nil
        }
        
        let pixelInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
        
        guard writer.canAdd(pixelInput) else {
            fatalError("[debug] parent abandons pixel writer child")
        }
        writer.add(pixelInput)
        
        self.adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: pixelInput, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(size.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(size.height)),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ])
        
        self.writer = writer
        
        self.duration = duration
        
        renderer.size = size
        
        // >_<
        
        let group = DispatchGroup()
        
        var tempRW = [(AVAssetReaderOutput, AVAssetWriterInput)]()
        
        guard let asset = asset else {
            writer.startWriting()
            writer.startSession(atSourceTime: kCMTimeZero)
            
            _init_worker()
            
            assetExportDoneFlag = true
            return
        }
//            let composition = AVMutableComposition()
//            
//            for track in asset.tracks {
//                let compoTrack = composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: kCMPersistentTrackID_Invalid)
//                
//                try! compoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, track.asset!.duration), of: track, at: kCMTimeZero)
//                compoTrack.preferredTransform = track.preferredTransform
//            }
//            
//            let immutableSnapshot = composition.copy() as! AVComposition
            
        guard let reader = try? AVAssetReader(asset: asset) else {
            print("[debug] AVAssetReader configuration fail for", asset)
            return
        }
        
        for track in asset.tracks {
            
            let output: AVAssetReaderTrackOutput
            let input: AVAssetWriterInput
            
            if (track.mediaType == AVMediaTypeVideo) {
                output = AVAssetReaderTrackOutput(track: track, outputSettings: videoSettings)
                input = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
                
            } else if (track.mediaType == AVMediaTypeAudio) {
                var audioFormat: CMFormatDescription? = nil
                _init_audioformatdesc(format: &audioFormat)
                
                output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
                input = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: nil, sourceFormatHint: audioFormat)
                
            } else {
                continue
            }
            
            output.alwaysCopiesSampleData = false
            
            guard reader.canAdd(output) else {
                fatalError("[debug] parent abandons reader child")
            }
            reader.add(output)
            
            guard writer.canAdd(input) else {
                fatalError("[debug] parent abandons writer child")
            }
            writer.add(input)
            
            tempRW.append((output, input))
        }
        
        reader.startReading()
        
        writer.startWriting()
        writer.startSession(atSourceTime: kCMTimeZero)
        
        for (index, (output, input)) in tempRW.enumerated() {
            let queue = DispatchQueue(label: "track #\(index)")
            
            group.enter()
            input.requestMediaDataWhenReady(on: queue) {
                while (input.isReadyForMoreMediaData) {
                    if let nextBuffer = output.copyNextSampleBuffer() {
                        input.append(nextBuffer)
                        
                    } else {
                        input.markAsFinished()
                        group.leave()
                        
                        reader.cancelReading()
                        return
                    }
                }
            }
        }
    
        _init_worker()
        
        group.notify(queue: DispatchQueue.global()) {
            self.assetExportDoneFlag = true
        }
    }
    
    private func _init_worker() {
        
        worker.async {
            self.workerBarrier!.wait()
            while let workerBarrier = self.workerBarrier {
                while (!self.adaptor.assetWriterInput.isReadyForMoreMediaData) {
                    
                }
                let (buffer, time) = self.pixels.removeFirst()
                self.adaptor.append(buffer, withPresentationTime: time)
                
                workerBarrier.wait()
            }
        }
        
    }
    
    private func _init_audioformatdesc(format: inout CMFormatDescription?) {
        var audioFormat = AudioStreamBasicDescription()
        bzero(&audioFormat, MemoryLayout<AudioStreamBasicDescription>.size)
        audioFormat.mSampleRate = 44100
        audioFormat.mFormatID = kAudioFormatMPEG4AAC
        audioFormat.mFramesPerPacket = 1024
        audioFormat.mChannelsPerFrame = 2
        
        let bytes_per_sample = MemoryLayout<Float>.size
        audioFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
        
        audioFormat.mBitsPerChannel = UInt32(bytes_per_sample * 8)
        audioFormat.mBytesPerPacket = UInt32(bytes_per_sample * 2)
        audioFormat.mBytesPerFrame = UInt32(bytes_per_sample * 2)
        
        CMAudioFormatDescriptionCreate(kCFAllocatorDefault,
                                       &audioFormat,
                                       0,
                                       nil,
                                       0,
                                       nil,
                                       nil,
                                       &format);
    }
    
    private func _append(buffer: CVPixelBuffer, time: CMTime) {
        pixels.append((buffer, time))
        workerBarrier!.signal()
        
        let progress = CMTimeGetSeconds(time) / CMTimeGetSeconds(duration)
        delegate?.appendingDone(session: self, buffer: buffer, time: time, progress: progress)
        
        appenderQueue.sync {
            self.appendingCount -= 1
        }
    }
    
    /*
     func append(image: CGImage, time: CMTime) {
     appenderQueue.sync {
     appendingCount += 1
     }
     
     if let pxbuffer = renderer.render(cgImage: image) {
     _append(buffer: pxbuffer, time: time)
     } else {
     fatalError("[debug] CG image rendering failure!")
     }
     }
     
     func append(view: UIView, time: CMTime) {
     appenderQueue.sync {
     appendingCount += 1
     }
     DispatchQueue.global().async {
     self.appenderQueue.asyncAfter(deadline: .now() + .milliseconds(10)) {
     self.appendingCount -= 1
     }
     
     let image = self.renderer.renderUIView(view: view)
     self.append(image: image!, time: time)
     }
     }
     */
    
    func append(view: UIView, playerView: PlayerView, targetType: EventSubject, time: CMTime) {
        appenderQueue.sync {
            appendingCount += 1
        }
        DispatchQueue.global().async {
            let buffer: CVPixelBuffer
            
            switch targetType {
            case .any: buffer = self.renderer.render(shapeView: view, playerView: playerView)
            case .shape: buffer = self.renderer.render(shapeView: view, playerView: nil)
            case .player: buffer = self.renderer.render(shapeView: nil, playerView: playerView)
            }
            
            self._append(buffer: buffer, time: time)
        }
    }
    
    func markAsFinished(completionHandler: (() -> Void)? = nil) {
        if marked {
            return
        }
        
        marked = true
        var periodicCheck: (() -> Void)!
        
        periodicCheck = {
            if (self.assetExportDoneFlag && self.appendingCount == 0 && self.pixels.count == 0) {
                let barrier = self.workerBarrier!
                self.workerBarrier = nil
                barrier.signal()
                
                self.adaptor.assetWriterInput.markAsFinished()
                
                self.writer.endSession(atSourceTime: self.duration)
                self.writer.finishWriting {
                    guard self.writer.status == .completed else {
                        print("writer error!", self.writer.status, self.writer.error ?? "nil")
                        return
                    }
                    DispatchQueue.main.async(execute: completionHandler ?? {})
                }
            } else {
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100), execute: periodicCheck)
            }
        }
        
        periodicCheck()
    }
}
