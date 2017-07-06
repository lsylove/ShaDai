//
//  HashTagViewController.swift
//  ShaDai
//
//  Created by chicpark7 on 06/07/2017.
//  Copyright © 2017 WebLinkTest. All rights reserved.
//

import UIKit

class HashTagViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


extension HashTagViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        
        print(textView.text)
        
    }

}
