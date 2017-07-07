//
//  AVViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 7..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class AVViewController: UIViewController {

    @IBOutlet weak var playerView: PlayerView!
    
    override func loadView() {
        super.loadView()
        
        let path = Bundle.main.path(forResource: "video.mp4", ofType: nil)!
        let url = URL(fileURLWithPath: path)
        
        playerView.player = AVPlayer(url: url)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        playerView.player?.play()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
