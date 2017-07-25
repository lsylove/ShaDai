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
    
    func execute(player: AVPlayer, animLayer: CAShapeLayer? = nil, completionHandler: (() -> Void)? = nil) {
        
        events.removeValue(forKey: -1)
        let executionBarrier = DispatchSemaphore(value: 1)
        
        sequentialConsumer.async {
            let keysSorted = self.events.keys.sorted()
            
            let temp = keysSorted.dropFirst()
            let seq = zip(keysSorted, temp)
            
            for (curr, next) in seq {
                let diff = Double(next - curr)
                executionBarrier.wait()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(diff * 1000.0 / self.frequency))) {
                    executionBarrier.signal()
                    for entity in self.events[next]! {
                        entity.execute(player: player, animLayer: animLayer, metadata: &self.metadata)
                    }
                }
            }
            DispatchQueue.main.async {
                completionHandler?()
            }
        }
    }
    
}
