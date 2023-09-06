//
//  File.swift
//
//
//  Created by my on 2023/9/6.
//

import Foundation
import SwiftSyntax

public final class SwiftSyntaxWalker: SyntaxVisitor {
    public enum SupportSyntaxDecl {
        case `class`
        case `protocol`
        case `struct`
        case `enum`
        case `import`
        case `extension`
        case `func`
        case `typealias`
        case macro
        case variable
        case enumCase
    }
    
    public let supportSyntaxDecls: [SupportSyntaxDecl]
    public let syntaxNode: SyntaxProtocol
    public init(_ viewMode: SyntaxTreeViewMode = .sourceAccurate,
                supportSyntaxDecls: [SupportSyntaxDecl] = [],
                syntaxNode: SyntaxProtocol)
    {
        if supportSyntaxDecls.isEmpty {
            self.supportSyntaxDecls = [
                .class, .protocol, .struct, .enum, .import, .extension, .func, .macro, .variable, .enumCase
            ]
        } else {
            self.supportSyntaxDecls = supportSyntaxDecls
        }
        self.syntaxNode = syntaxNode
        super.init(viewMode: viewMode)
    }
    
    private var walkSyntaxs: [SyntaxProtocol] = []
    
    @discardableResult
    public func walk() -> [SyntaxProtocol] {
        walk(syntaxNode)
        return walkSyntaxs
    }
    
    @discardableResult
    private func appnedNode(_ node: SyntaxProtocol, supportType: SupportSyntaxDecl) -> SyntaxVisitorContinueKind {
        guard node._syntaxNode != syntaxNode._syntaxNode,
                supportSyntaxDecls.contains(supportType)
        else {
            return .visitChildren
        }
        walkSyntaxs.append(node)
        return .skipChildren
    }
    
    override public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .class)
    }
    
    override public func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .protocol)
    }
    
    override public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .struct)
    }
    
    override public func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .enum)
    }
    
    override public func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .extension)
    }
    
    override public func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .import)
    }
    
    override public func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .macro)
    }
    
    override public func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .typealias)
    }
    
    override public func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .func)
    }
    
    override public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .variable)
    }
    
    override public func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        appnedNode(node, supportType: .enumCase)
    }
}
