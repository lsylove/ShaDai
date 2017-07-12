//
//  PlayerView.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 6..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    // User Defined
    var playCallback: (() -> Void)?
    
    var pauseCallback: (() -> Void)?
    
    func play() {
        if let pl = playerLayer.player {
            pl.play()
            playCallback?()
        }
    }
    
    func pause() {
        if let pl = playerLayer.player {
            pl.pause()
            pauseCallback?()
        }
    }
    
    func toggle() {
        if let pl = playerLayer.player {
            if pl.timeControlStatus == .playing {
                pause()
            } else if pl.timeControlStatus == .paused {
                play()
            }
        }
    }
}
