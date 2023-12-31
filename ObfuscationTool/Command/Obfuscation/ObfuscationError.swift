//
//  ObfuscationError.swift
//  Command
//
//  Created by mayong on 2023/9/27.
//

import Foundation

enum ObfuscationError: Error, CustomStringConvertible {
    case unknownTemplateError(String)
    case unknownArgument(String, String)
    case underlyingError(Error)
    case outputEmpty
    case outputIsFile(String)
    case codeCannotWrite(String)
    
    var message: String {
        switch self {
        case let .unknownTemplateError(templateType):
            return "unknonw template type \(templateType)"
        case let .unknownArgument(argument, expectedType):
            return "unknonw argument \(argument) expected type \(expectedType)"
        case let .underlyingError(error):
            return "system error occurred \(error)"
        case .outputEmpty:
            return "output is empty"
        case let .outputIsFile(outputFile):
            return "output is file \(outputFile)"
        case let .codeCannotWrite(code):
            return "code \(code) write error"
        }
    }
    
    var description: String {
        message
    }
}
