//
//  PrefixAdd.swift
//  Command
//
//  Created by mayong on 2025/7/22.
//

import SwiftSyntax

class PrefixRewriter: SyntaxRewriter {
    let prefix: String

    init(prefix: String) {
        self.prefix = prefix
    }

    // MARK: - 变量名加前缀

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        let newBindings = node.bindings.map { binding -> PatternBindingSyntax in
            guard let identPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                return binding
            }

            let originalName = identPattern.identifier.text
            if originalName.hasPrefix(prefix) {
                return binding
            }

            let newIdent = TokenSyntax.identifier(prefix + originalName)
            let newPattern = identPattern.with(\.identifier, newIdent)
            return binding.with(\.pattern, PatternSyntax(newPattern))
        }

        let newNode = node.with(\.bindings, PatternBindingListSyntax(newBindings))
        return DeclSyntax(newNode)
    }

    // MARK: - 函数名加前缀

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        let originalName = node.name.text
        if originalName.hasPrefix(prefix) {
            return DeclSyntax(node)
        }

        let newIdent = TokenSyntax.identifier(prefix + originalName)
        let newNode = node.with(\.name, newIdent)
        return DeclSyntax(newNode)
    }

    // MARK: - 类名加前缀

//    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
//        let originalName = node.name.text
//        if originalName.hasPrefix(prefix) {
//            return DeclSyntax(node)
//        }
//
//        let newIdent = TokenSyntax.identifier(prefix + originalName)
//        let newNode = node.with(\.name, newIdent)
//        return DeclSyntax(newNode)
//    }

    // MARK: - 结构体名加前缀

//    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
//        let originalName = node.name.text
//        if originalName.hasPrefix(prefix) {
//            return DeclSyntax(node)
//        }
//
//        let newIdent = TokenSyntax.identifier(prefix + originalName)
//        let newNode = node.with(\.name, newIdent)
//        return DeclSyntax(newNode)
//    }

    // MARK: - 枚举名加前缀
    override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        // 遍历每个 case 元素
        let newElements = node.elements.map { enumCaseElement -> EnumCaseElementSyntax in
            let originalName = enumCaseElement.name.text
            if originalName.hasPrefix(prefix) {
                return enumCaseElement
            }
            let newIdent = TokenSyntax.identifier(prefix + originalName)
            return enumCaseElement.with(\.name, newIdent)
        }
        let newNode = node.with(\.elements, EnumCaseElementListSyntax(newElements))
        return DeclSyntax(newNode)
    }

    // MARK: - 函数参数名加前缀（可选，慎用）

    override func visit(_ node: FunctionParameterClauseSyntax) -> FunctionParameterClauseSyntax {
        let newParameterList = node.parameters.map { param -> FunctionParameterSyntax in
            let firstName = param.firstName
            if firstName.text.hasPrefix(prefix) {
                return param
            }
            let newFirstName = TokenSyntax.identifier(prefix + firstName.text)
            return param.with(\.firstName, newFirstName)
        }

        return node.with(\.parameters, FunctionParameterListSyntax(newParameterList))
    }
}
