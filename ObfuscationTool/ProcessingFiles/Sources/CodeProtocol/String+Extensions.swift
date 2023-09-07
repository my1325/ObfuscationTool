//
//  File.swift
//  
//
//  Created by mayong on 2023/9/7.
//

import Foundation

extension String {
    func replaceOrAddPrefix(_ prefix: String, separator: Character?) -> String {
        guard let separator else { return String(format: "%@%@", prefix, self) }
        if let index = firstIndex(of: separator) {
            if index == startIndex {
                return String(format: "%@%@", prefix, self)
            } else {
                let range = startIndex ..< index
                return self.replacingCharacters(in: range, with: prefix)
            }
        }
        return String(format: "%@%@%@", prefix, String(separator), self)
    }
}
