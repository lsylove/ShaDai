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
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(HashTagViewController.cancelEdit))
        
        view.addGestureRecognizer(tap)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func cancelEdit() {
        view.endEditing(true)
    }

}

extension HashTagViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        
        let ranges = textView.text.hashTagRange
        let attribute = [ NSForegroundColorAttributeName: UIColor.white ]
        let attributedText = NSMutableAttributedString(string: textView.text, attributes: attribute)
        
        ranges.forEach{attributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.blue, range: $0)}
        
        textView.attributedText = attributedText
        
    }

}
