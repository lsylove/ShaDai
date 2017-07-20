//
//  TimemarkParams.swift
//  ShaDai
//
//  Created by lsylove on 2017. 7. 20..
//  Copyright © 2017년 WebLinkTest. All rights reserved.
//

import Foundation

struct TimemarkParams<T> where T: Equatable, T: Hashable {
    
    let sub: [T]
    
    let offset: [T:[Double]]
    
    let timemarks: [Double]
    
    let mark: [T:[Double]]
    
    init(a: T, b: T, markA: [Double], markB: [Double]) {
        assert(markA.count == markB.count, "The length of timemark arrays are different")
        
        mark = [ a: markA, b: markB ]
        
        var dif = 0.0
        let diffA = markA.map { a -> Double in defer { dif = a }; return a - dif }
        
        dif = 0.0
        let diffB = markB.map { a -> Double in defer { dif = a }; return a - dif }
        
        let zipped = zip(diffA, diffB)
        
        sub = zipped.map { $0 > $1 ? b : a }
        let mins = zipped.map { min($0, $1) }
        let diff = zipped.map { abs($0 - $1) }
        
        var _offset = [T:[Double]]()
        
        var sum = 0.0
        _offset[a] = zip(sub, diff).flatMap { [0.0, $0 == a ? -$1 : 0.0] }.map { (sum += $0, sum).1 }
        
        sum = 0.0
        _offset[b] = zip(sub, diff).flatMap { [0.0, $0 == b ? -$1 : 0.0] }.map { (sum += $0, sum).1 }
        
        offset = _offset
        
        sum = 0.0
        timemarks = zip(mins, diff).flatMap { [$0, $1] }.map { (sum += $0, sum).1 }
    }
    
    func state(_ time: Double) -> Int {
        for (index, mark) in timemarks.enumerated() {
            if (mark > time) {
                return index
            }
        }
        return timemarks.count - 1
    }
    
    func shouldPause(_ obj: T, trackTime: Double) -> Bool {
        let s = state(trackTime)
        return s % 2 != 0 && sub[s / 2] == obj
    }
    
    func shouldPause(_ obj: T, playTime: Double, threshold: Double = 0.02) -> Bool {
        guard let _mark = mark[obj] else {
            print("[debug] unregistered object for shouldPause()")
            return false
        }
        for mark in _mark {
            if (abs(playTime - mark) < threshold) {
                return true
            }
        }
        return false
    }
    
    func trackTimeToPlayTime(_ obj: T, trackTime: Double) -> Double {
        let s = state(trackTime)
        guard let off = offset[obj] else {
            print("[debug] unregistered object for trackTimeToPlayTime()")
            return trackTime
        }
        if (s != 0 && abs(off[s] - off[s - 1]) > 0.02) {
            return timemarks[s] + off[s]
        } else {
            return trackTime + off[s]
        }
    }
}
