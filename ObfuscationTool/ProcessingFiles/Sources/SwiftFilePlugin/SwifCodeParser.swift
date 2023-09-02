//
//  File.swift
//  
//
//  Created by my on 2023/9/2.
//

import Foundation
import SwiftSyntax

open class SwiftFileSyntaxParser: SyntaxAnyVisitor {
    
    open override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    open override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    open override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    open override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    open override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
    
    open override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        return .skipChildren
    }
}
