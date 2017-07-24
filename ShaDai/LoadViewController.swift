//
//  LoadViewController.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 24..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import UIKit

class LoadViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "load" {
            return nil != Bundle.main.path(forResource: textField.text, ofType: "mp4")
        } else {
            return true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "load" {
            let dst = segue.destination as! EditorViewController
            dst.url = Bundle.main.path(forResource: textField.text, ofType: "mp4")
        }
    }

}
