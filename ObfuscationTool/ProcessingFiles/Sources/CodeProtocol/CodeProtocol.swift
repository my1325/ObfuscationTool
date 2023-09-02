//
//  File.swift
//  
//
//  Created by my on 2023/9/2.
//

import Foundation

public enum CodeType {
    case codeClass
    case codeStruct
    case codeEnum
    case codeFunc
    case codeProperty
    case codeImport
    case codeLine
}

public protocol CodeProtocol {
    var codeType: CodeType { get }
    
    var codeRawValue: String { get }
    
    var codeName: String { get }
    
    var children: [CodeProtocol] { get }
}

public typealias Code = CodeProtocol
