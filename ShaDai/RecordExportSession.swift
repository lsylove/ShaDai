//
//  RecordExportSession.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 28..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVFoundation
import AVKit

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
    
    init?(fileURL: URL, size: CGSize, duration: CMTime, assets: [AVAsset]? = nil) {
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8 * 65536,
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
                print("appending buffer", time, self.adaptor.append(buffer, withPresentationTime: time))
                
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
        
        appenderQueue.async {
            self.appendingCount -= 1
        }
    }
    
    func append(image: CGImage, time: CMTime) {
        appenderQueue.sync {
            appendingCount += 1
            
            self.serial.async {
                let imageWidth = Int(image.width)
                let imageHeight = Int(image.height)
                
                let attributes : [NSObject:AnyObject] = [
                    kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
                    kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
                ]
                
                var _pxbuffer: CVPixelBuffer?
                CVPixelBufferCreate(kCFAllocatorDefault,
                                    imageWidth,
                                    imageHeight,
                                    kCVPixelFormatType_32ARGB,
                                    attributes as CFDictionary?,
                                    &_pxbuffer)
                
                guard let pxbuffer = _pxbuffer else {
                    return
                }
                let flags = CVPixelBufferLockFlags(rawValue: 0)
                CVPixelBufferLockBaseAddress(pxbuffer, flags)
                let pxdata = CVPixelBufferGetBaseAddress(pxbuffer)
                
                let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
                let _context = CGContext(data: pxdata,
                                         width: imageWidth,
                                         height: imageHeight,
                                         bitsPerComponent: 8,
                                         bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer),
                                         space: rgbColorSpace,
                                         bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
                
                guard let context = _context else {
                    CVPixelBufferUnlockBaseAddress(pxbuffer, flags)
                    return
                }
                
                context.draw(image, in: CGRect.init(x: 0, y: 0, width: imageWidth, height: imageHeight))
                CVPixelBufferUnlockBaseAddress(pxbuffer, flags)
                self._append(buffer: pxbuffer, time: time)
            }
        }
    }
    
    func append(view: UIView, time: CMTime) {
        appenderQueue.sync {
            appendingCount += 1
        }
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        self.append(image: image!.cgImage!, time: time)
        self.appenderQueue.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.appendingCount -= 1
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
                print("checking good")
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
