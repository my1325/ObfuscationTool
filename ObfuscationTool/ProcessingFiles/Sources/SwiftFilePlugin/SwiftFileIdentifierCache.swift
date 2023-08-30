//
//  File.swift
//  
//
//  Created by mayong on 2023/8/29.
//

import Foundation
import SwiftString

internal final class SwiftFileIdentifierCache {
    private(set) var cacheQueue: [SwiftString] = []
    let identifier: SwiftFilePatterns
    init(identifier: SwiftFilePatterns, cacheQueue: [SwiftString] = []) {
        self.identifier = identifier
        self.cacheQueue = cacheQueue
    }
    
    // asldjflkasdfl
    var isEmpty: Bool { cacheQueue.isEmpty }
    
    // aslkdjflasd
    var peek: SwiftString? { cacheQueue.first }
    
    // asdfasd
    func resetCache(_ cache: [SwiftString]) { // asdjflkasdf
        self/*asjdflkasdfl*/.cacheQueue = cache // asdjflaksdjfa
    }
    
    func dequeue() -> SwiftString? {
        guard !isEmpty else { return nil }
        return cacheQueue.removeFirst()
    }
}
