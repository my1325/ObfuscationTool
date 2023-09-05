//
//  File.swift
//  
//
//  Created by my on 2023/9/5.
//

import Foundation

public struct Code: CodeProtocol {
    public let type: CodeType
    
    public let content: String
    
    public let rawName: String
    
    public init(type: CodeType, content: String, rawName: String) {
        self.type = type
        self.content = content
        self.rawName = rawName
    }
}

public extension CodeProtocol {
    func asCode() -> Code {
        Code(type: type, content: content, rawName: rawName)
    }
}

public struct CodeContainer: CodeContainerProtocol {
    public let type: CodeContainerType
    
    public let entireDeclare: String
    
    public private(set) var code: [CodeRawProtocol]
    
    public let rawName: String
    
    public init(type: CodeContainerType, entireDeclare: String, code: [CodeRawProtocol], rawName: String) {
        self.type = type
        self.entireDeclare = entireDeclare
        self.code = code
        self.rawName = rawName
    }
}

public extension CodeContainerProtocol {
    func asCodeContainer() -> CodeContainer {
        CodeContainer(type: type, entireDeclare: entireDeclare, code: code, rawName: rawName)
    }
}

public protocol CodeShullffleProtocol {
    mutating func shulffle(_ order: Bool)
    
    func shulffed(_ order: Bool) -> Self
}

extension CodeShullffleProtocol {
    public func shulffle(_ code: CodeRawProtocol, order: Bool) -> CodeRawProtocol {
        if let codeContainer = code as? CodeContainerProtocol {
            return codeContainer.asCodeContainer().shulffed(order)
        }
        return code
    }
}

extension CodeContainer: CodeShullffleProtocol {
    public mutating func shulffle(_ order: Bool) {
        var codes = code.map({ shulffle($0, order: order) })
        if order {
            codes = codes.sorted(by: { $0.order < $1.order })
                .grouped({ $0.order == $1.order })
                .map({ $0.shuffled() })
                .flatMap({ $0 })
        } else {
            codes = codes.shuffled()
        }
        code = codes
    }
    
    public func shulffed(_ order: Bool) -> CodeContainer {
        var codes = code.map({ shulffle($0, order: order) })
        if order {
            codes = codes.sorted(by: { $0.order < $1.order })
                .grouped({ $0.order == $1.order })
                .map({ $0.shuffled() })
                .flatMap({ $0 })
        } else {
            codes = codes.shuffled()
        }
        return CodeContainer(type: type, entireDeclare: entireDeclare, code: codes, rawName: rawName)
    }
}
