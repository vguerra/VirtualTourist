//
//  Shuffle.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 20/09/15.
//  Copyright © 2015 Victor Guerra. All rights reserved.
//

// Borrowed from https://gist.github.com/natecook1000/0ac03efe07f647b46dae

import Foundation

//extension Array
//{
//    /** Randomizes the order of an array's elements. */
//    mutating func shuffle() {
//        for _ in 0..<10
//        {
//            sortInPlace { (_,_) in arc4random() < arc4random() }
//        }
//    }
//}

extension MutableCollectionType where Self.Index == Int {
    mutating func shuffleInPlace() {
        let c = self.count
        for i in 0..<(c - 1) {
            let j = Int(arc4random_uniform(UInt32(c - i - 1))) + i + 1
            swap(&self[i], &self[j])
        }
    }
}

extension MutableCollectionType where Self.Index == Int {
    func shuffle() -> Self {
        var r = self
        let c = self.count
        for i in 0..<(c - 1) {
            let j = Int(arc4random_uniform(UInt32(c - i - 1))) + i + 1
            swap(&r[i], &r[j])
        }
        return r
    }
}