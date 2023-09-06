////
////  File.swift
////
////
//  Created by my on 2023/9/2.
//

import Foundation
import SwiftSyntax
import SwiftParser
import ProcessingFiles
import CodeProtocol
import FilePath

open class SwiftFileProcessingPlugin: ProcessingFilePlugin {
        
    public func processingManager(_ manager: ProcessingManager, processedFile file: FilePath) throws -> [CodeRawProtocol] {
        let url = URL(fileURLWithPath: file.path)
        let data = try Data(contentsOf: url)
        guard let source = String(data: data, encoding: .utf8) else {
            throw ProcessingError.fileReadError(file)
        }

        var parser = Parser(source)
        let fileSyntax = SourceFileSyntax.parse(from: &parser)
        let walker = SwiftSyntaxWalker()
        walker.walk(fileSyntax)
            
    }
}

public final class SwiftSyntaxWalker: SyntaxAnyVisitor {
    public enum SupportSyntaxDecl {
        case `class`
        case `protocol`
        case `struct`
        case `enum`
        case `import`
        case `extension`
        case `func`
        case macro
        case variable
        
        public var syntaxDeclType: DeclSyntaxProtocol.Type {
            switch self {
            case .class: return ClassDeclSyntax.self
            case .protocol: return ProtocolDeclSyntax.self
            case .struct: return StructDeclSyntax.self
            case .enum: return EnumDeclSyntax.self
            case .import: return ImportDeclSyntax.self
            case .extension: return ExtensionDeclSyntax.self
            case .func: return FunctionDeclSyntax.self
            case .macro: return IfConfigDeclSyntax.self
            case .variable: return VariableDeclSyntax.self
            }
        }
        
        public func isSupportNode(_ node: Syntax) -> Bool {
            switch self {
            case .class: return node.isProtocol(ClassDeclSyntax) Class
            case .protocol: return ProtocolDeclSyntax.self
            case .struct: return StructDeclSyntax.self
            case .enum: return EnumDeclSyntax.self
            case .import: return ImportDeclSyntax.self
            case .extension: return ExtensionDeclSyntax.self
            case .func: return FunctionDeclSyntax.self
            case .macro: return IfConfigDeclSyntax.self
            case .variable: return VariableDeclSyntax.self
            }
        }
    }
    
    public let supportSyntaxDecls: [SupportSyntaxDecl]
    private let supportTypes: [DeclSyntaxProtocol.Type]
    public init(viewMode: SyntaxTreeViewMode = .sourceAccurate, supportSyntaxDecls: [SupportSyntaxDecl] = []) {
        if supportSyntaxDecls.isEmpty {
            self.supportSyntaxDecls = [
                .class, .protocol, .struct, .enum, .import, .extension, .func, .macro, .variable
            ]
        } else {
            self.supportSyntaxDecls = supportSyntaxDecls
        }
        self.supportTypes = self.supportSyntaxDecls.map(\.syntaxDeclType)
        super.init(viewMode: viewMode)
    }
    
    private var walkSyntaxs: [Syntax] = []
    
    public func walkNode(_ node: Syntax) -> [Syntax] {
        walk(node)
        return walkSyntaxs
    }
    
    public override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        let condition: (DeclSyntaxProtocol.Type) -> Bool = {
            node.asProtocol(<#T##SyntaxProtocol.Protocol#>)
        }
        if supportTypes.contains(where: condition) {
            walkSyntaxs.append(node)
        }
        return .skipChildren
    }
}

