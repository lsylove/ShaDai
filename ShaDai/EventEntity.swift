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
    func execute(player: AVPlayer, animLayer: CAShapeLayer?)
}

enum PlayEvent: EventEntity {
    case play
    case pause
    
    func execute(player: AVPlayer, animLayer: CAShapeLayer?) {
        switch self {
        case .play: player.play()
        case .pause: player.pause()
        }
    }
}

enum FrameEvent: Int, EventEntity {
    case forward = 1
    case backward = -1
    
    func execute(player: AVPlayer, animLayer: CAShapeLayer?) {
        player.currentItem?.step(byCount: self.rawValue)
    }
}

class PlaybackEvent: EventEntity {
    let steps: Int
    init(_ steps: Int) {
        self.steps = steps
    }
    
    func execute(player: AVPlayer, animLayer: CAShapeLayer?) {
        player.currentItem?.step(byCount: self.steps)
    }
}
