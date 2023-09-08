//
//  File.swift
//
//
//  Created by my on 2023/9/5.
//

import Foundation

public struct CodeRawWord: CodeRawWordProtocol {
    public var identifier: CodeRawWordIdentifier
    
    public var content: String

    public init(identifier: CodeRawWordIdentifier, content: String) {
        self.identifier = identifier
        self.content = content
    }
}

extension CodeRawWordProtocol {
    public func asWord() -> CodeRawWord {
        CodeRawWord(identifier: identifier, content: content)
    }
    
    public func newWord(_ content: String) -> CodeRawWordProtocol {
        CodeRawWord(identifier: identifier, content: content)
    }
}

public struct Code: CodeProtocol {
    public let type: CodeType
        
    public let rawName: String
    
    public let words: [CodeRawWordProtocol]
    
    public init(type: CodeType, words: [CodeRawWordProtocol], rawName: String) {
        self.type = type
        self.words = words
        self.rawName = rawName
    }
}

public extension CodeProtocol {
    func asCode() -> Code {
        Code(type: type, words: words, rawName: rawName)
    }
}

public struct CodeContainer: CodeContainerProtocol {
    public var entireDeclareWord: [CodeRawWordProtocol]
    
    public let type: CodeContainerType
        
    public let code: [CodeRawProtocol]
    
    public let rawName: String
    
    public init(type: CodeContainerType,
                entireDeclareWord: [CodeRawWordProtocol],
                code: [CodeRawProtocol],
                rawName: String)
    {
        self.type = type
        self.entireDeclareWord = entireDeclareWord
        self.code = code
        self.rawName = rawName
    }
}

public struct CodeMapLazyContainer {
    
    let codeContainer: CodeContainerProtocol
    let block: (CodeRawProtocol) -> CodeRawProtocol
    init(codeContainer: CodeContainerProtocol, block: @escaping (CodeRawProtocol) -> CodeRawProtocol) {
        self.codeContainer = codeContainer
        self.block = block
    }
    
    init(other: CodeMapLazyContainer, block: @escaping (CodeRawProtocol) -> CodeRawProtocol) {
        self.codeContainer = other.codeContainer
        self.block = { block(other.block($0)) }
    }
        
    public func mapCode(_ type: [CodeType] = [], block: @escaping (CodeProtocol) -> CodeProtocol) -> CodeMapLazyContainer {
        CodeMapLazyContainer(other: self, block: {
            if let code = $0 as? CodeProtocol, type.isEmpty || type.contains(code.type) {
                return block(code)
            }
            return $0
        })
    }
    
    public func mapCodeContainer(_ type: [CodeContainerType] = [], block: @escaping (CodeContainerProtocol) -> CodeContainerProtocol) -> CodeMapLazyContainer {
        CodeMapLazyContainer(other: self, block: {
            if let code = $0 as? CodeContainerProtocol, type.isEmpty || type.contains(code.type) {
                return block(code)
            }
            return $0
        })
    }
    
    public func asCodeContainer() -> CodeContainerProtocol {
        codeContainer.mapRawCode(block)
    }
}

public extension CodeContainerProtocol {
    
    func asCodeContainer() -> CodeContainer {
        CodeContainer(type: type, entireDeclareWord: entireDeclareWord, code: code, rawName: rawName)
    }
    
    func newCode(_ newCode: [CodeRawProtocol], newDeclareWord: [CodeRawWordProtocol]) -> CodeContainer {
        CodeContainer(type: type, entireDeclareWord: newDeclareWord, code: newCode, rawName: rawName)
    }
    
    func mapRawCode(_ block: @escaping (CodeRawProtocol) -> CodeRawProtocol) -> CodeContainerProtocol {
        newCode(code.map(block), newDeclareWord: entireDeclareWord)
    }
    
    func mapCode(_ type: [CodeType] = [], block: @escaping (CodeProtocol) -> CodeProtocol) -> CodeMapLazyContainer {
        CodeMapLazyContainer(codeContainer: self, block: {
            if let code = $0 as? CodeProtocol, type.isEmpty || type.contains(code.type) {
                return block(code)
            }
            return $0
        })
    }
    
    func mapCodeContainer(_ type: [CodeContainerType] = [], block: @escaping (CodeContainerProtocol) -> CodeContainerProtocol) -> CodeMapLazyContainer {
        CodeMapLazyContainer(codeContainer: self, block: {
            if let code = $0 as? CodeContainerProtocol, type.isEmpty || type.contains(code.type) {
                return block(code)
            }
            return $0
        })
    }
}

// MARK: - Shullffle

public protocol CodeShullffleProtocol {
    func shulffed(_ order: Bool) -> Self
}

public extension CodeShullffleProtocol {
    func shulffle(_ code: CodeRawProtocol, order: Bool) -> CodeRawProtocol {
        if let codeContainer = code as? CodeContainerProtocol {
            return codeContainer.asCodeContainer().shulffed(order)
        }
        return code
    }
}

extension CodeContainer: CodeShullffleProtocol {
    public func shulffed(_ order: Bool) -> CodeContainer {
        var codes = code.map { shulffle($0, order: order) }
        if order {
            codes = codes.sorted(by: { $0.order < $1.order })
                .grouped { $0.order == $1.order }
                .map { $0.shuffled() }
                .flatMap { $0 }
        } else {
            codes = codes.shuffled()
        }
        return CodeContainer(type: type, entireDeclareWord: entireDeclareWord, code: codes, rawName: rawName)
    }
}
