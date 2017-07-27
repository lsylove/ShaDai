//
//  EventEntity.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 24..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import AVFoundation
import AVKit

protocol EventEntity {
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String])
}

struct VoidEvent: EventEntity {
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
    }
}

enum PlayEvent: EventEntity {
    case play
    case pause
    
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
        switch self {
        case .play: playInternal(player: player, rate: metadata["rate"])
        case .pause: player.pause()
        }
    }
    
    private func playInternal(player: AVPlayer, rate: String?) {
        if let db = Float(rate ?? "1.0") {
            player.playImmediately(atRate: db)
        } else {
            player.play()
        }
    }
}

enum FrameEvent: Int, EventEntity {
    case forward = 1
    case backward = -1
    
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
        player.currentItem?.step(byCount: self.rawValue)
    }
}

class PlaybackEvent: EventEntity {
    let steps: Int
    init(_ steps: Int) {
        self.steps = steps
    }
    
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
        player.currentItem?.step(byCount: self.steps)
    }
}

class RateEvent: EventEntity {
    let rate: Float
    init(_ rate: Float) {
        self.rate = rate
    }
    
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
        metadata["rate"] = String(format: "%4.3f", rate)
        if (player.timeControlStatus == .playing) {
            player.rate = rate
        }
    }

}

class SeekEvent: EventEntity {
    let position: CMTime
    init(_ position: CMTime) {
        self.position = position
    }
    
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
        let mark = CMTimeMakeWithSeconds(0.0002, 1)
        player.seek(to: position, toleranceBefore: mark, toleranceAfter: mark)
    }
}

class ArbitraryEvent: EventEntity {
    let callback: (AVPlayer, UIView, inout [String : String]) -> Void
    init(_ callback: @escaping (AVPlayer, UIView, inout [String : String]) -> Void) {
        self.callback = callback
    }
    
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
        callback(player, superView, &metadata)
    }
}

class SegmentedControlEvent: EventEntity {
    let control: UISegmentedControl
    let index: Int
    init(_ control: UISegmentedControl, _ index: Int) {
        self.control = control
        self.index = index
    }
    
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
        control.selectedSegmentIndex = index
    }
}

// >_< >_<

class ShapeRelatedEvent: EventEntity {
    let shape: ShapeView
    let optionalCallback: ((ShapeView, AVPlayer, UIView, inout [String : String]) -> Void)?
    init(_ shape: ShapeView, optionalCallback: ((ShapeView, AVPlayer, UIView, inout [String : String]) -> Void)? = nil) {
        self.shape = shape
        self.optionalCallback = optionalCallback
    }
    
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
        if let optionalCallback = optionalCallback {
            optionalCallback(shape, player, superView, &metadata)
        }
    }
}

class PanningEvent: EventEntity {
    let shape: ShapeView
    let point: CGPoint
    let operation: (ShapeView, CGPoint) -> Void
    init(_ shape: ShapeView, _ point: CGPoint, operation: @escaping (ShapeView, CGPoint) -> Void) {
        self.shape = shape
        self.point = point
        self.operation = operation
    }
    
    func execute(player: AVPlayer, superView: UIView, metadata: inout [String : String]) {
        operation(shape, point)
    }
}
