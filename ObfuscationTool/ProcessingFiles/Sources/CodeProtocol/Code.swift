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
    
    func renamed(_ name: String) -> CodeProtocol {
        RenameCode(self, newName: name)
            .asCode()!
    }
    
    func replaceOrAddPrefrexToName(_ prefix: String, separator: Character?) -> CodeProtocol {
        PrefixNameCode(self, prefix: prefix, prefixSeparator: separator)
            .asCode()!
    }
}

public struct CodeContainer: CodeContainerProtocol {
    public let type: CodeContainerType
    
    public let entireDeclare: String
    
    public let code: [CodeRawProtocol]
    
    public let rawName: String
    
    public var content: String {
        if _content.isEmpty {
            return String(format: "%@ {%@\n}", entireDeclare, code.map(\.content).joined())
        } else {
            return _content
        }
    }
    
    private let _content: String
    
    public init(type: CodeContainerType,
                entireDeclare: String,
                code: [CodeRawProtocol],
                rawName: String,
                content: String = "")
    {
        self.type = type
        self.entireDeclare = entireDeclare
        self.code = code
        self.rawName = rawName
        self._content = content
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
        CodeContainer(type: type, entireDeclare: entireDeclare, code: code, rawName: rawName, content: content)
    }
    
    func renamed(_ name: String) -> CodeContainerProtocol {
        RenameCode(self, newName: name)
            .asCodeContainer()!
    }
    
    func replaceOrAddPrefrexToName(_ prefix: String, separator: Character?) -> CodeContainerProtocol {
        PrefixNameCode(self, prefix: prefix, prefixSeparator: separator)
            .asCodeContainer()!
    }
    
    func newCode(_ newCode: [CodeRawProtocol]) -> CodeContainer {
        CodeContainer(type: type, entireDeclare: entireDeclare, code: newCode, rawName: rawName)
    }
    
    func mapRawCode(_ block: @escaping (CodeRawProtocol) -> CodeRawProtocol) -> CodeContainerProtocol {
        newCode(code.map(block))
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
        return CodeContainer(type: type, entireDeclare: entireDeclare, code: codes, rawName: rawName)
    }
}

// MARK: - rename

protocol CodeInnerProtocol {
    var innerCode: CodeRawProtocol { get }
    
    var isCode: Bool { get }
    
    var isCodeContainer: Bool { get }
    
    func asCode() -> CodeProtocol?
    
    func asCodeContainer() -> CodeContainerProtocol?
}

extension CodeInnerProtocol where Self: CodeRawProtocol {
    
    var isCode: Bool {
        innerCode is CodeProtocol
    }
    
    var isCodeContainer: Bool {
        innerCode is CodeContainerProtocol
    }
    
    func asCode() -> CodeProtocol? {
        guard let code = innerCode as? CodeProtocol else { return nil }
        return Code(type: code.type, content: content, rawName: rawName)
    }
    
    func asCodeContainer() -> CodeContainerProtocol? {
        guard let code = innerCode as? CodeContainerProtocol else { return nil }
        return CodeContainer(type: code.type,
                             entireDeclare: code.entireDeclare,
                             code: code.code,
                             rawName: rawName,
                             content: content)
    }
    
    func asRawCode() -> CodeRawProtocol {
        if isCode { return asCode()! }
        return asCodeContainer()!
    }
}

struct RenameCode: CodeRawProtocol, CodeInnerProtocol {
    let innerCode: CodeRawProtocol
    let newName: String
    init(_ code: CodeRawProtocol, newName: String) {
        self.innerCode = code
        self.newName = newName
    }
    
    var rawName: String { newName }
    
    var content: String { innerCode.content.replacingOccurrences(of: innerCode.rawName, with: newName) }
    
    var order: CodeOrder { innerCode.order }
    
    func asCodeContainer() -> CodeContainerProtocol? {
        guard let code = innerCode as? CodeContainerProtocol else { return nil }
        return CodeContainer(type: code.type,
                             entireDeclare: code.entireDeclare.replacingOccurrences(of: code.rawName, with: newName),
                             code: code.code,
                             rawName: rawName,
                             content: content)
    }
}

struct PrefixNameCode: CodeRawProtocol, CodeInnerProtocol {
    private(set) var content: String = ""
    
    private(set) var order: CodeOrder = .none
    
    private(set) var rawName: String = ""
    
    let innerCode: CodeRawProtocol
    let prefix: String
    let separator: Character?
    init(_ innerCode: CodeRawProtocol, prefix: String, prefixSeparator: Character?) {
        self.innerCode = innerCode
        self.prefix = prefix
        self.separator = prefixSeparator
    }
    
    func asCode() -> CodeProtocol? {
        guard let code = innerCode as? CodeProtocol else { return nil }
        let newName = code.rawName.replaceOrAddPrefix(prefix, separator: separator)
        return RenameCode(innerCode, newName: newName)
            .asCode()
    }
    
    func asCodeContainer() -> CodeContainerProtocol? {
        guard let code = innerCode as? CodeContainerProtocol else { return nil }
        let newName = code.rawName.replaceOrAddPrefix(prefix, separator: separator)
        return RenameCode(code, newName: newName)
            .asCodeContainer()
    }
}
