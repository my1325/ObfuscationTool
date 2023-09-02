//
//  File.swift
//  
//
//  Created by my on 2023/9/2.
//

import Foundation
import FilePath
import CodeProtocol

public enum FileType {
    /// .swift
    case fSwift
    /// .h
    case fHeader
    /// .m
    case fImplemention
    /// other
    case other
    
    init(ext: String) {
        switch ext {
        case "h": self = .fHeader
        case "swift": self = .fSwift
        case "m": self = .fImplemention
        default: self = .other
        }
    }
}

public protocol ProcessingFileProtocol {
    
    var fileType: FileType { get }
    
    var filePath: FilePath { get }
    
    var code: [Code] { get }
}

public typealias ProcessingFile = ProcessingFileProtocol

extension ProcessingFile {
    var content: String {
        code.reduce("", { $0.appending($1.codeRawValue) })
    }
}
