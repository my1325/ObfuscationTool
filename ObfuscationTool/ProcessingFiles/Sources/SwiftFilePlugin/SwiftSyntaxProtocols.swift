//
//  File.swift
//
//
//  Created by my on 2023/9/3.
//

import CodeProtocol
import Foundation
import SwiftSyntax

public protocol CustomNamedDeclSyntax {
    var syntaxName: String { get }
}

public extension CustomNamedDeclSyntax where Self: SyntaxProtocol {
    var syntaxName: String {
        ""
    }

    var body: String {
        contentForToken(self)
    }

    func contentForToken(_ token: SyntaxProtocol) -> String {
        String(data: Data(token.syntaxTextBytes), encoding: .utf8)!
    }
}

extension TokenKind {
    var isVariable: Bool {
        switch self {
        case let .keyword(keyword): return [Keyword.var, .let].contains(keyword)
        default: return false
        }
    }
    
    var isIdentifier: Bool {
        switch self {
        case .identifier: return true
        default: return false
        }
    }
}

extension CustomNamedDeclSyntax where Self == VariableDeclSyntax {
    public var syntaxName: String {
        if let token = self.tokens(viewMode: .sourceAccurate).first(where: { $0.tokenKind.isVariable }),
           let name = token.nextToken(viewMode: .sourceAccurate)?.text
        {
            return name
        }
        return ""
    }
}

extension CustomNamedDeclSyntax where Self == EnumCaseDeclSyntax {
    public var syntaxName: String {
        if let token = self.tokens(viewMode: .sourceAccurate).first(where: { $0.tokenKind.isIdentifier }) {
            return token.text
        }
        return ""
    }
}

public extension CustomNamedDeclSyntax where Self: DeclSyntaxProtocol {
    var declareTokens: [TokenSyntax] {
        tokens(viewMode: .sourceAccurate).prefix(while: { $0.tokenKind != .leftBrace })
    }
}

public extension CustomNamedDeclSyntax where Self: NamedDeclSyntax {
    var syntaxName: String {
        name.description
    }
}

public protocol CustomCodeContainerSyntaxProtocol {}
public protocol CustomCodeSyntaxProtocol {}

extension CustomCodeContainerSyntaxProtocol {
    var type: CodeContainerType {
        switch self.self {
        case is ClassDeclSyntax: return .class
        case is StructDeclSyntax: return .struct
        case is EnumDeclSyntax: return .enum
        case is ProtocolDeclSyntax: return .protocol
        case is ExtensionDeclSyntax: return .extension
        case is OperatorDeclSyntax: return .operator
        default: return .block
        }
    }
}

extension CustomCodeSyntaxProtocol {
    var type: CodeType {
        switch self.self {
        case is VariableDeclSyntax: return .property
        case is FunctionDeclSyntax: return .func
        case is ImportDeclSyntax: return .import
        case is IfConfigDeclSyntax: return .macro
        case is InitializerDeclSyntax: return .`init`
        case is DeinitializerDeclSyntax: return .deinit
        case is SubscriptDeclSyntax: return .subscript
        case is EnumCaseDeclSyntax: return .enumCase
        default: return .line
        }
    }
}

extension VariableDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}
extension FunctionDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}
extension ImportDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}
extension IfConfigDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}
extension TypeAliasDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}
extension EnumCaseDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}
extension InitializerDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}
extension DeinitializerDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}
extension SubscriptDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}
extension AssociatedTypeDeclSyntax: CustomNamedDeclSyntax, CustomCodeSyntaxProtocol {}

extension ClassDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension ActorDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension StructDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension ProtocolDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension EnumDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension ExtensionDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension OperatorDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}

// MARK: - -

public struct CodeContainerSyntax<S: CustomCodeContainerSyntaxProtocol & CustomNamedDeclSyntax>: CodeContainerProtocol where S: DeclSyntaxProtocol {
    public var entireDeclareWord: [CodeRawWordProtocol] { syntaxNode.declareTokens }
    
    public var code: [CodeRawProtocol] {
        SwiftSyntaxWalker(syntaxNode: syntaxNode)
            .walk()
            .map(\.asRawCode)
    }

    public var rawName: String { syntaxNode.syntaxName }

    public var type: CodeContainerType { syntaxNode.type }
    
    public let syntaxNode: S
    public init(syntaxNode: S) {
        self.syntaxNode = syntaxNode
    }
}

// MAKR: --
extension TokenSyntax: @retroactive CodeRawWordProtocol {
    public var identifier: CodeRawWordIdentifier {
        switch tokenKind {
        case .identifier: return .identifier
        default: return .word
        }
    }
    
    public var content: String {
        String(data: Data(syntaxTextBytes), encoding: .utf8)!
    }
}

extension TokenSequence {
    public func asArray() -> [TokenSyntax] {
        map({ $0 })
    }
}

// MARK: --

public struct CodeSyntax<S: CustomCodeSyntaxProtocol & CustomNamedDeclSyntax>: CodeProtocol where S: SyntaxProtocol {
    public var words: [CodeRawWordProtocol] { syntaxNode.tokens(viewMode: .sourceAccurate).asArray() }
    
    public var rawName: String { syntaxNode.syntaxName }

    public var type: CodeType { syntaxNode.type }

    public let syntaxNode: S
    public init(syntaxNode: S) {
        self.syntaxNode = syntaxNode
    }
}

// MARK: --
extension SyntaxProtocol where Self: CustomCodeSyntaxProtocol, Self: CustomNamedDeclSyntax {
    public func asCode() -> CodeProtocol {
        CodeSyntax(syntaxNode: self)
    }
}

extension DeclSyntaxProtocol where Self: CustomCodeContainerSyntaxProtocol, Self: CustomNamedDeclSyntax {
    public func asCodeContainer() -> CodeContainerProtocol {
        CodeContainerSyntax(syntaxNode: self)
    }
}

extension SyntaxProtocol {
    public var asRawCode: CodeRawProtocol {
        if let node = self as? ClassDeclSyntax {
            return CodeContainerSyntax(syntaxNode: node)
        } else if let node = self as? StructDeclSyntax {
            return CodeContainerSyntax(syntaxNode: node)
        } else if let node = self as? EnumDeclSyntax {
            return CodeContainerSyntax(syntaxNode: node)
        } else if let node = self as? ProtocolDeclSyntax {
            return CodeContainerSyntax(syntaxNode: node)
        } else if let node = self as? ExtensionDeclSyntax {
            return CodeContainerSyntax(syntaxNode: node)
        } else if let node = self as? OperatorDeclSyntax {
            return CodeContainerSyntax(syntaxNode: node)
        } else if let node = self as? FunctionDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? VariableDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? TypeAliasDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? ImportDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? IfConfigDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? EnumCaseDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? InitializerDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? DeinitializerDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? SubscriptDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? AssociatedTypeDeclSyntax {
            return CodeSyntax(syntaxNode: node)
        } else if let node = self as? ActorDeclSyntax {
            return CodeContainerSyntax(syntaxNode: node)
        } else {
            fatalError("unknown type \(self)")
        }
    }
}
