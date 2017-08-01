//
//  VoiceRecorderViewController.swift
//  ShaDai
//
//  Created by chicpark7 on 28/07/2017.
//  Copyright © 2017 WebLinkTest. All rights reserved.
//

import UIKit
import AVFoundation


class VoiceRecorderViewController: UIViewController, AVAudioRecorderDelegate {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    
    let recorderSettings = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    lazy var outputURL: URL = {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("temp.wav")
    }()

    var audioRecorder: AVAudioRecorder?
    var player: AVPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try! session.setActive(true)

    }
    
    @IBAction func onPlay() {
    
        self.progressView.progress = 0
        
        self.player = AVPlayer(url: self.outputURL)
        self.player?.addPeriodicTimeObserver(forInterval: CMTimeMake(30, 1000),
                                             queue: .main,
                                             using: { [weak self] time in
          
                                                if let duration = self?.player?.currentItem?.duration.seconds {

                                                    self?.progressView.progress = Float(time.seconds / duration)
                                                    
                                                }
        
        })
        self.player?.play()
        
    }
    
    @IBAction func onRecord() {
        
        if self.audioRecorder?.isRecording == true {
            
            self.audioRecorder?.stop()
            
        }
        else {
            
            self.recordButton.setTitle("Stop Recording", for: .normal)
            do {
                
                self.audioRecorder = try AVAudioRecorder(url: outputURL,
                                                    settings: recorderSettings)
                self.audioRecorder?.delegate = self
                self.audioRecorder?.record()
            }
            catch {
                print(error)
            }
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        self.recordButton.setTitle("Record", for: .normal)
        
    }
}
