//
//  File.swift
//  
//
//  Created by my on 2023/9/5.
//

import Foundation

public extension Array {
    func grouped(_ by: @escaping (Element, Element) -> Bool) -> [[Element]] {
        var retValue: [[Element]] = Array<[Element]>(repeating: [], count: count)
        var length = 0
        for e in self {
            var i = 0
            while i < length {
                let subValue = retValue[i]
                if by(e, subValue[0]) { break }
                i += 1
            }
            var subValue = retValue[i]
            subValue.append(e)
            retValue[i] = subValue
            if i == length { length += 1 }
        }
        return retValue.prefix(upTo: length).map({ $0 })
    }
}
