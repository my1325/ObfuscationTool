//
//  File.swift
//
//
//  Created by my on 2023/9/3.
//

import Foundation
import CodeProtocol
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
        let data = Data(token.syntaxTextBytes)
        return String(data: data, encoding: .utf8)!
    }
}

public extension CustomNamedDeclSyntax where Self: DeclSyntaxProtocol {
    var declareString: String {
        let child = children(viewMode: .sourceAccurate).first
        var optionalToken = child?.nextToken(viewMode: .sourceAccurate)
        var tokenString: String = ""
        while let token = optionalToken, token.tokenKind != .leftBrace {
            tokenString = tokenString.appending(contentForToken(token))
            optionalToken = token.nextToken(viewMode: .sourceAccurate)
        }
        return tokenString
    }
}

public extension CustomNamedDeclSyntax where Self: NamedDeclSyntax {
    var syntaxName: String {
        name.description
    }
}

extension VariableDeclSyntax: CustomNamedDeclSyntax {}
extension FunctionDeclSyntax: CustomNamedDeclSyntax {}
extension ImportDeclSyntax: CustomNamedDeclSyntax {}
extension IfConfigDeclSyntax: CustomNamedDeclSyntax {}
extension TypeAliasDeclSyntax: CustomNamedDeclSyntax {}

extension EnumCaseDeclSyntax: CustomNamedDeclSyntax {}
extension ClassDeclSyntax: CustomNamedDeclSyntax {}
extension StructDeclSyntax: CustomNamedDeclSyntax {}
extension ProtocolDeclSyntax: CustomNamedDeclSyntax {}
extension EnumDeclSyntax: CustomNamedDeclSyntax {}
extension ExtensionDeclSyntax: CustomNamedDeclSyntax {}

// MARK: --
struct CodeContainerSyntax<S: DeclSyntaxProtocol & CustomNamedDeclSyntax>: CodeContainerProtocol {
    var code: [CodeRawProtocol] = []
    
    let type: CodeContainerType
    let syntaxNode: S
    init(syntaxNode: S, type: CodeContainerType) {
        self.syntaxNode = syntaxNode
        self.type = type
    }
    
    var rawName: String { syntaxNode.syntaxName }
    
    var entireDeclare: String { syntaxNode.declareString }
}

// MARK: -
struct CodeSyntax<S: SyntaxProtocol & CustomNamedDeclSyntax>: CodeProtocol {
    let syntaxNode: S
    let type: CodeType
    init(syntaxNode: S, type: CodeType) {
        self.syntaxNode = syntaxNode
        self.type = type
    }
    
    var rawName: String { syntaxNode.syntaxName }
    
    var content: String { syntaxNode.body }
}
