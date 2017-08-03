//
//  RecordSession.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 24..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVFoundation
import AVKit

protocol ProgressReporter {
    
}

protocol ProgressReporterDelegate {
    func reportProgress(reporter: ProgressReporter, progress: Double, count: Int?)
}

class RecordSession {
    private var events: [Int : [EventEntity]] = [0 : [VoidEvent()]]
    
    private var ticks = 1
    
    private let frequency: Double
    
    private var timer: Timer?
    
    private var _active = true
    
    private let sequentialConsumer = DispatchQueue(label: "sequential")
    
    fileprivate let rendererBarrier = DispatchSemaphore(value: 1)
    
    var delegate: ProgressReporterDelegate?
    
    var active: Bool {
        get {
            return _active
        }
    }
    
    var metadata: [String : String] = [:]
    
    var asset: AVAsset?
    
    init(frequency: Double) {
        self.frequency = frequency
        
        timer = Timer.scheduledTimer(timeInterval: 1.0 / frequency, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
    }
    
    func deactivateSession() -> Bool {
        guard _active else {
            return false
        }
        
        _active = false
        
        timer?.invalidate()
        timer = nil
        ticks = -1
        
        print("[debug] the number of records in the session: \(events.count)")
        
        return true
    }
    
    @objc private func tick() {
        ticks += 1
    }
    
    func record(entity: EventEntity) {
        if events[ticks] != nil {
            events[ticks]!.append(entity)
        } else {
            events[ticks] = [entity]
        }
    }
    
    func execute(playerView: PlayerView, superView: UIView, completionHandler: (() -> Void)? = nil) {
        
        events.removeValue(forKey: -1)
        let executionBarrier = DispatchSemaphore(value: 1)
        
        sequentialConsumer.async {
            let keysSorted = self.events.keys.sorted()
            let seq = zip(keysSorted, keysSorted.dropFirst())
            
            for (curr, next) in seq {
                let diff = Double(next - curr)
                executionBarrier.wait()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(diff * 1000.0 / self.frequency))) {
                    executionBarrier.signal()
                    for entity in self.events[next]! {
                        entity.execute(player: playerView.player!, superView: superView, metadata: &self.metadata)
                    }
                }
            }
            DispatchQueue.main.async {
                completionHandler?()
            }
        }
    }
    
    func exportAsFile(playerView: PlayerView, view: UIView, fileURL: URL, completionHandler: (() -> Void)? = nil) {
        
        let timeout = 1
        
        events.removeValue(forKey: -1)
        let keysSorted = self.events.keys.sorted()
        
        var size = playerView.playerLayer.videoRect.size
        size.width *= UIScreen.main.scale
        size.height *= UIScreen.main.scale
        
        let duration = CMTime(seconds: Double(keysSorted.last!) / self.frequency + Double(timeout), preferredTimescale: 1000)
        
        guard let exportSession = RecordExportSession(fileURL: fileURL, size: size, duration: duration, asset: asset) else {
            print("[debug] failed to initialize exportSession")
            return
        }
        exportSession.delegate = self
        
        sequentialConsumer.async {
            
            var progressCount = 0
            
            for ticks in keysSorted {
                
                self.rendererBarrier.wait()
                
                let progress = Double(progressCount) / Double(self.events.count)
                self.delegate?.reportProgress(reporter: self, progress: progress, count: self.events.count)
                
                progressCount += 1
                
                DispatchQueue.main.async {
                    var targetType = self.events[ticks]!.first!.target
                    
                    for entity in self.events[ticks]! {
                        targetType = targetType != entity.target ? .any : targetType
                        entity.execute(player: playerView.player!, superView: view, metadata: &self.metadata)
                    }
//                    exportSession.append(view: view, time: time)
                    
                    let time = CMTime(seconds: Double(ticks) / self.frequency, preferredTimescale: 1000)
                    
                    exportSession.append(view: view, playerView: playerView, targetType: targetType, time: time)
                }
            }
            
            self.rendererBarrier.wait()
            exportSession.markAsFinished(completionHandler: completionHandler)
        }
    }
}

extension RecordSession: RecordExportSessionDelegate {
    
    func appendingDone(session: RecordExportSession, buffer: CVPixelBuffer, time: CMTime, progress: Double) {
        rendererBarrier.signal()
    }
    
}

extension RecordSession: ProgressReporter {
    
}
