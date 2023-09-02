//
//  File.swift
//  
//
//  Created by my on 2023/9/2.
//

import Foundation
import ProcessingFiles
import FilePath
import CodeProtocol
import SwiftSyntax
import SwiftParser

public final class SwiftProcessingFile: SyntaxAnyVisitor, ProcessingFile {
    public class func parseFileAtPath(_ filePath: FilePath) throws -> SwiftProcessingFile {
        let processer = SwiftProcessingFile(filePath)
        try processer.processing()
        return processer
    }
    
    public let fileType: FileType = .fSwift
    
    public private(set) var code: [Code] = []

    public let filePath: FilePath
    
    init(_ filePath: FilePath) {
        self.filePath = filePath
        super.init(viewMode: .sourceAccurate)
    }
    
    func processing() throws {
        let url = URL(fileURLWithPath: filePath.path)
        let data = try Data(contentsOf: url)
        guard let source = String(data: data, encoding: .utf8) else {
            throw ProcessingError.fileReadError(filePath)
        }
        
        var parser = Parser(source)
        let fileSyntax = SourceFileSyntax.parse(from: &parser)
        walk(fileSyntax)
    }
    
    public override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftJustLineCode(codeType: .codeLine, codeName: node.nameString, codeRawValue: node.bodyString))
        return .skipChildren
    }
    
    public override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftImportCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftFuncCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftClassCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftVarCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftIfConfigCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftClassCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftClassCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftEnumCode(node))
        return .skipChildren
    }
    
    public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        code.append(SwiftClassCode(node))
        return .skipChildren
    }
}
