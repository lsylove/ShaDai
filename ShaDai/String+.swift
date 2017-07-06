//
//  String+.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 6..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import Foundation

extension String {
    var hashTagSubstring: [String] {
        guard let regex = try? NSRegularExpression(pattern: "(?<=^#|\\s#)\\w+(?=\\s|$)") else {
            return []
        }
        let nsString = self as NSString
        let results = regex.matches(in: self, range: NSMakeRange(0, nsString.length))
        return results.map{nsString.substring(with: $0.range)}
    }
    
    var hashTagRange: [NSRange] {
        guard let regex = try? NSRegularExpression(pattern: "(?<=^|\\s)#\\w+(?=\\s|$)") else {
            return []
        }
        let nsString = self as NSString
        let results = regex.matches(in: self, range: NSMakeRange(0, nsString.length))
        return results.map{$0.range}
    }
}
