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
        tokens(viewMode: .sourceAccurate).first(where: { !$0.text.isEmpty })?.text ?? ""
    }

    var body: String {
        contentForToken(self)
    }

    func contentForToken(_ token: SyntaxProtocol) -> String {
        String(data: Data(token.syntaxTextBytes), encoding: .utf8)!
    }
}

public extension CustomNamedDeclSyntax where Self: DeclSyntaxProtocol {
    var declareString: String {
        tokens(viewMode: .sourceAccurate)
            .prefix(while: { $0.tokenKind != .leftBrace })
            .map { contentForToken($0) }
            .joined()
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

extension ClassDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension StructDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension ProtocolDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension EnumDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}
extension ExtensionDeclSyntax: CustomNamedDeclSyntax, CustomCodeContainerSyntaxProtocol {}

// MARK: - -

struct CodeContainerSyntax<S: CustomCodeContainerSyntaxProtocol & CustomNamedDeclSyntax>: CodeContainerProtocol where S: DeclSyntaxProtocol {
    var code: [CodeRawProtocol] = []

    var rawName: String { syntaxNode.syntaxName }

    var entireDeclare: String { syntaxNode.declareString }

    var type: CodeContainerType { syntaxNode.type }
    
    let syntaxNode: S
    init(syntaxNode: S) {
        self.syntaxNode = syntaxNode
    }
}

// MARK: -

struct CodeSyntax<S: CustomCodeSyntaxProtocol & CustomNamedDeclSyntax>: CodeProtocol where S: SyntaxProtocol {
    var rawName: String { syntaxNode.syntaxName }

    var content: String { syntaxNode.body }

    var type: CodeType { syntaxNode.type }

    let syntaxNode: S
    init(syntaxNode: S) {
        self.syntaxNode = syntaxNode
    }
}
