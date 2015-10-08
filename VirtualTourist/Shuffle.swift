//
//  Shuffle.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 20/09/15.
//  Copyright © 2015 Victor Guerra. All rights reserved.
//

// Borrowed from https://gist.github.com/natecook1000/0ac03efe07f647b46dae
// with a small fix to avoid swap between the same elements

import Foundation

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