//
//  File.swift
//  
//
//  Created by mayong on 2023/8/28.
//

import Foundation
import SwiftString

protocol Pattern {
    var pattern: String { get }
    init(pattern: String)
}

extension Pattern {
    static func namePattern() -> Self {
        Self(pattern: "\\s\\w+\\s")
    }
}

protocol ProcessingIdentifierPattern: Pattern {
    static func partternWithIdentifierMatch(_ identifier: ProcessingIdentifier) -> Self
}

extension ProcessingIdentifierPattern {
    static func partternWithIdentifierMatch(_ identifier: ProcessingIdentifier) -> Self {
        let pattern = String(format: "%@\\s\\w+\\siEnd$", identifier.rawValue)
        return Self(pattern: pattern)
    }
}

struct CommonProcessingIdentifierPattern: ProcessingIdentifierPattern {
    var pattern: String
    
    static let classMatch = partternWithIdentifierMatch(.iClass)
    
    static let structMatch = partternWithIdentifierMatch(.iStruct)
    
    static let enumMatch = partternWithIdentifierMatch(.iEnum)
    
    static let propertyMatch = partternWithIdentifierMatch(.iProperty)
    
    static let funcMatch = partternWithIdentifierMatch(.iFunc)
    
    static let extensionMatch = partternWithIdentifierMatch(.iExtension)
    
    static let fileMatch = partternWithIdentifierMatch(.iFile)
}

extension SwiftString {
    func match(_ pattern: CommonProcessingIdentifierPattern) -> Bool {
        match(pattern.pattern)
    }
    
    static func =~(_ lhs: SwiftString, _ rhs: CommonProcessingIdentifierPattern) -> Bool {
        lhs.match(rhs)
    }
    
    func matches(_ pattern: CommonProcessingIdentifierPattern) -> [SwiftString] {
        do {
            return try matches(pattern.pattern).map({ SwiftString(string: $0) })
        } catch {
            debugPrint(error)
            return []
        }
    }
    
    func replaceWithMatches(_ pattern: CommonProcessingIdentifierPattern, template: String) -> SwiftString {
        do {
            return SwiftString(string: try replaceWithMatches(pattern.pattern, with: template))
        } catch {
            debugPrint(error)
            return SwiftString(string: string)
        }
    }
}
