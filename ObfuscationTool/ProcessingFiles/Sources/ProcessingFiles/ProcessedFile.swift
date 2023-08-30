//
//  File.swift
//  
//
//  Created by mayong on 2023/8/28.
//

import Foundation
import FilePath

public enum ProcessingIdentifier: String {
    case iEmpty
    case iClass
    case iProperty
    case iFunc
    case iDocument
    case iHeader
    case iCode
}

public protocol ProcessingLine {
    // should be entire if identifier = (iFunc/iProperty/iDocument/iCode)
    var rawValue: String { get }
    
    var identifier: ProcessingIdentifier { get }
    
    // can not be empty if identifier = (iClass/iFunc/iProperty)
    var name: String { get }
    
    var lines: [ProcessingLine] { get }
}

public final class ProcessedFile {
    let path: FilePath
    public let lines: [ProcessingLine]
    public init(lines: [ProcessingLine], path: FilePath) {
        self.lines = lines
        self.path = path
    }
}
