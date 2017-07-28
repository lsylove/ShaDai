//
//  RecordSession.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 24..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVFoundation
import AVKit

class RecordSession {
    private var events: [Int : [EventEntity]] = [0 : [VoidEvent()]]
    
    private var ticks = 1
    
    private let frequency: Double
    
    private var timer: Timer?
    
    private var _active = true
    
    private let sequentialConsumer = DispatchQueue(label: "sequential")
    
    var active: Bool {
        get {
            return _active
        }
    }
    
    var metadata: [String : String] = [:]
    
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
        if nil != events[ticks] {
            events[ticks]!.append(entity)
        } else {
            events[ticks] = [entity]
        }
    }
    
    func execute(player: AVPlayer, superView: UIView, completionHandler: (() -> Void)? = nil) {
        
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
                        entity.execute(player: player, superView: superView, metadata: &self.metadata)
                    }
                }
            }
            DispatchQueue.main.async {
                completionHandler?()
            }
        }
    }
    
    func exportAsFile(player: AVPlayer, view: UIView, fileURL: URL, completionHandler: (() -> Void)? = nil) {
        
        events.removeValue(forKey: -1)
        let keysSorted = self.events.keys.sorted()
        
        let duration = CMTime(seconds: Double(keysSorted.last!) * 10 / self.frequency + 10.0, preferredTimescale: 1000)
        print("duration: ", duration)
        
        guard let exportSession = RecordExportSession(fileURL: fileURL, size: view.frame.size, duration: duration) else {
            print("[debug] failed to initialize exportSession")
            return
        }
        
        DispatchQueue.main.async {
            
            for ticks in keysSorted {
                for entity in self.events[ticks]! {
                    entity.execute(player: player, superView: view, metadata: &self.metadata)
                }
                exportSession.append(view: view, time: CMTime(seconds: Double(ticks) * 10 / self.frequency, preferredTimescale: 1000))
            }
            exportSession.markAsFinished(completionHandler: completionHandler)
        }
    }
}
