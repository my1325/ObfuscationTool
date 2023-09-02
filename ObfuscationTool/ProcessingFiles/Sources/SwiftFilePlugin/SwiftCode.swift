//
//  File.swift
//  
//
//  Created by my on 2023/9/2.
//

import Foundation
import CodeProtocol
import SwiftSyntax

extension Code {
    public var codeName: String { "" }

    public var codeRawValue: String {
        children.reduce("", { $0.appending($1.codeRawValue) })
    }
}

protocol SwiftCodeNameStringSyntax {
    var nameString: String { get }
}

protocol SwiftCodeNameSyntax: SwiftCodeNameStringSyntax {
    var name: TokenSyntax { get }
}

extension SwiftCodeNameSyntax {
    var nameString: String { name.description }
}

protocol SwiftCodeNameStringImplSyntax: SwiftCodeNameStringSyntax {
    func tokens(viewMode: SyntaxTreeViewMode) -> TokenSequence
}

extension SwiftCodeNameStringImplSyntax {
    var nameString: String {
        tokens(viewMode: .sourceAccurate).first(where: { !$0.text.isEmpty })?.text ?? ""
    }
}

extension SyntaxProtocol {
    var bodyString: String {
        let data = Data(syntaxTextBytes)
        return String(data: data, encoding: .utf8)!
    }
}

extension DeclSyntaxProtocol {
    var declareString: String {
        let child = children(viewMode: .sourceAccurate).first
        var optionalToken = child?.nextToken(viewMode: .sourceAccurate)
        var tokenString: String = ""
        while let token = optionalToken, token.tokenKind != .leftBrace {
            tokenString = tokenString.appending(token.bodyString)
            optionalToken = token.nextToken(viewMode: .sourceAccurate)
        }
        return tokenString
    }
}

extension ClassDeclSyntax: SwiftCodeNameSyntax {}
extension FunctionDeclSyntax: SwiftCodeNameSyntax {}
extension StructDeclSyntax: SwiftCodeNameSyntax {}
extension ProtocolDeclSyntax: SwiftCodeNameSyntax {}
extension EnumDeclSyntax: SwiftCodeNameSyntax {}
extension TypeAliasDeclSyntax: SwiftCodeNameSyntax {}
extension ExtensionDeclSyntax: SwiftCodeNameStringImplSyntax {}
extension VariableDeclSyntax: SwiftCodeNameStringImplSyntax {}
extension EnumCaseDeclSyntax: SwiftCodeNameStringImplSyntax {}

open class SwiftJustLineCode: Code {
    public let codeType: CodeType
    
    public let children: [CodeProtocol] = []
    
    public let codeName: String
    
    public let codeRawValue: String
    
    init(codeType: CodeType, codeName: String, codeRawValue: String) {
        self.codeType = codeType
        self.codeName = codeName
        self.codeRawValue = codeRawValue
    }
}

public final class SwiftFuncCode: SwiftJustLineCode {
    
    public init(_ node: FunctionDeclSyntax) {
        let codeRawValue = node.bodyString
        let codeName = node.nameString
        super.init(codeType: .codeFunc, codeName: codeName, codeRawValue: codeRawValue)
    }
    
    public init(_ node: InitializerDeclSyntax) {
        let codeRawValue = node.bodyString
        let codeName = "init"
        super.init(codeType: .codeFunc, codeName: codeName, codeRawValue: codeRawValue)
    }
    
    public init(_ node: DeinitializerDeclSyntax) {
        let codeRawValue = node.bodyString
        let codeName = "deinit"
        super.init(codeType: .codeFunc, codeName: codeName, codeRawValue: codeRawValue)
    }
}

public final class SwiftVarCode: SwiftJustLineCode {
    init(_ node: VariableDeclSyntax) {
        let codeRawValue = node.bodyString
        let codeName = node.nameString
        super.init(codeType: .codeProperty, codeName: codeName, codeRawValue: codeRawValue)
    }
}

public typealias SwiftSingleImportCode = SwiftImportCode.SwiftSingleImportCode
public final class SwiftImportCode: Code {
    public let codeType: CodeType = .codeImport
    
    public var children: [Code] = []
        
    public final class SwiftSingleImportCode: Code {
        public let codeType: CodeType = .codeImport
        
        public var codeRawValue: String
                
        public let children: [CodeProtocol] = []
        
        init(_ node: ImportDeclSyntax) {
            codeRawValue = node.bodyString
        }
        
        init(_ tokens: TokenSequence) {
            codeRawValue = tokens.reduce("", { $0.appending($1.bodyString) })
        }
    }
    
    func append(_ code: SwiftSingleImportCode) {
        children.append(code)
    }
    
    public init(_ node: ImportDeclSyntax) {
        children.append(SwiftSingleImportCode(node))
    }
    
    public init(_ tokens: TokenSequence) {
        children.append(SwiftSingleImportCode(tokens))
    }
}

public final class SwiftIfConfigCode: SyntaxAnyVisitor, Code {
    public struct IFConfigType: OptionSet {
        public typealias RawValue = Int
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let ifNone: IFConfigType = .init(rawValue: 0 << 1)
        
        public static let ifImport: IFConfigType = .init(rawValue: 1 << 1)
        
        public static let ifVar: IFConfigType = .init(rawValue: 1 << 2)
        
        public static let ifFunc: IFConfigType = .init(rawValue: 1 << 3)
        
        public var isNone: Bool { self == .ifNone }
        
        public var isImport: Bool { self == .ifImport }
        
        public var isVar: Bool { self == .ifVar }
        
        public var isFunc: Bool { self == .ifFunc }
        
        public var isMix: Bool { !(isNone || isImport || isVar || isFunc) }
    }
    
    public private(set) var ifConfigType: IFConfigType = .ifNone
    
    public let codeType: CodeType = .codeLine
    
    public let children: [Code] = []
    
    public var codeRawValue: String { node.bodyString }
    
    var tokens: TokenSequence {
        node.tokens(viewMode: .sourceAccurate)
    }
    
    let node: IfConfigDeclSyntax
    init(_ node: IfConfigDeclSyntax) {
        self.node = node
        super.init(viewMode: .sourceAccurate)
        self.walk(node)
    }
    
    public override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        ifConfigType.formUnion(.ifImport)
        return .skipChildren
    }
    
    public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        ifConfigType.formUnion(.ifFunc)
        return .skipChildren
    }
    
    public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        ifConfigType.formUnion(.ifVar)
        return .skipChildren
    }
}

public final class SwiftClassCode: SyntaxAnyVisitor, Code {
    public var codeType: CodeType = .codeClass
    
    public var codeName: String
    
    public var children: [Code] = []
    
    let declareString: String
    
    public var codeRawValue: String { String(format: "%@ {%@\n}", declareString, children.reduce("", { $0.appending($1.codeRawValue) })) }

//    let node: ClassDeclSyntax
    init(_ node: ClassDeclSyntax) {
        self.codeName = node.nameString
        self.codeType = .codeClass
        self.declareString = node.declareString
        super.init(viewMode: .sourceAccurate)
        self.walk(node)
    }
    
    init(_ node: StructDeclSyntax) {
        self.codeName = node.nameString
        self.codeType = .codeStruct
        self.declareString = node.declareString
        super.init(viewMode: .sourceAccurate)
        self.walk(node)
    }
    
    init(_ node: ProtocolDeclSyntax) {
        self.codeName = node.nameString
        self.codeType = .codeClass
        self.declareString = node.declareString
        super.init(viewMode: .sourceAccurate)
        self.walk(node)
    }
    
    init(_ node: ExtensionDeclSyntax) {
        self.codeName = node.nameString
        self.codeType = .codeClass
        self.declareString = node.declareString
        super.init(viewMode: .sourceAccurate)
        self.walk(node)
    }
    
    public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.nameString != codeName else { return .visitChildren }
        children.append(SwiftClassCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftVarCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftFuncCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftFuncCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftFuncCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftIfConfigCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftJustLineCode(codeType: .codeLine, codeName: node.nameString, codeRawValue: node.bodyString))
        return .skipChildren
    }
    
    public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftEnumCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.nameString != codeName else { return .visitChildren }
        children.append(SwiftClassCode(node))
        return .skipChildren
    }
}

public final class SwiftEnumCode: SyntaxAnyVisitor, Code {
    public let codeType: CodeType = .codeEnum
    
    public var children: [Code] = []
    
    public let codeName: String
    
    public var codeRawValue: String {
        String(format: "%@ {%@%@\n}", declareString,
               caseCode.reduce("", { $0.appending($1.codeRawValue) }),
               children.reduce("", { $0.appending($1.codeRawValue) })
        )
    }
    
    public var caseCode: [SwiftJustLineCode] = []
    
    let declareString: String
    
    init(_ node: EnumDeclSyntax) {
        self.codeName = node.nameString
        self.declareString = node.declareString
        super.init(viewMode: .sourceAccurate)
        self.walk(node)
    }
        
    public override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftIfConfigCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftJustLineCode(codeType: .codeLine, codeName: node.nameString, codeRawValue: node.bodyString))
        return .skipChildren
    }
    
    public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.nameString != codeName else { return .visitChildren }
        children.append(SwiftEnumCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftClassCode(node))
        return .skipChildren
    }

    public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftClassCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftVarCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftFuncCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
        children.append(SwiftJustLineCode(codeType: .codeEnum, codeName: node.nameString, codeRawValue: node.bodyString))
        return .skipChildren
    }
}
