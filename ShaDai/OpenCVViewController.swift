//
//  OpenCVViewController.swift
//  ShaDai
//
//  Created by chicpark7 on 03/08/2017.
//  Copyright © 2017 WebLinkTest. All rights reserved.
//

import UIKit
import OpenAL

class OpenCVViewController: UIViewController {

    @IBOutlet var image: UIImageView!
    let baseImage = #imageLiteral(resourceName: "test4.png")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.image.image = baseImage
        
        // Do any additional setup after loading the view.
    }

    @IBAction func onDetactFace() {
    
        self.image.image = OpenCVWrapper.detectFace(baseImage)
        
    }
    
    @IBAction func onSkeletonization() {
        
        self.image.image = OpenCVWrapper.detactSkeleton(baseImage)
        
    }

}
