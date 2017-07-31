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
    func appendingDone(session: RecordExportSession, buffer: CVPixelBuffer, time: CMTime)
}

class RecordExportSession {
    
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
    
    private let renderer = ImageRenderer()
    
    var delegate: RecordExportSessionDelegate?
    
    init?(fileURL: URL, size: CGSize, duration: CMTime, assets: [AVAsset]? = nil) {
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 64 * 65536,
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
        
        var assetStorage = [(AVAssetReader, AVAssetReaderOutput, AVAssetWriterInput)]()
        
        assets?.forEach {
            guard let reader = try? AVAssetReader(asset: $0) else {
                print("[debug] AVAssetReader configuration fail")
                return
            }
            
            let output = AVAssetReaderVideoCompositionOutput(videoTracks: $0.tracks, videoSettings: videoSettings)
            guard reader.canAdd(output) else {
                fatalError("[debug] parent abandons reader child")
            }
            reader.add(output)
            
            let input = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings)
            guard writer.canAdd(input) else {
                fatalError("[debug] parent abandons writer child")
            }
            writer.add(input)
            
            assetStorage.append((reader, output, input))
        }
        
        self.adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: pixelInput, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferWidthKey as String: NSNumber(value: Float(size.width)),
            kCVPixelBufferHeightKey as String: NSNumber(value: Float(size.height)),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ])
        
        self.writer = writer
        writer.startWriting()
        writer.startSession(atSourceTime: kCMTimeZero)
        
        self.duration = duration
        
        _init_assetexport(assets: assetStorage)
    }
    
    private func _init_assetexport(assets: [(AVAssetReader, AVAssetReaderOutput, AVAssetWriterInput)]) {
        let group = DispatchGroup()
        
        for (reader, output, input) in assets {
            reader.startReading()
            let queue = DispatchQueue(label: reader.description)
            
            group.enter()
            input.requestMediaDataWhenReady(on: queue) {
                while (input.isReadyForMoreMediaData) {
                    if let nextBuffer = output.copyNextSampleBuffer() {
                        input.append(nextBuffer)
                        
                    } else {
                        input.markAsFinished()
                        group.leave()
                        break
                    }
                }
            }
        }
        
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
        
        group.notify(queue: DispatchQueue.global()) {
            self.assetExportDoneFlag = true
        }
    }
    
    private func _append(buffer: CVPixelBuffer, time: CMTime) {
        var buffer: CVPixelBuffer? = buffer
        //        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
        
        pixels.append((buffer!, time))
        workerBarrier!.signal()
        
        delegate?.appendingDone(session: self, buffer: buffer!, time: time)
        
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
            print("periodic checking", self.assetExportDoneFlag, self.appendingCount, self.pixels.count)
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
