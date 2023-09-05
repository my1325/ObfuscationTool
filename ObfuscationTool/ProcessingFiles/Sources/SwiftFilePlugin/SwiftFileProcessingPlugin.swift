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
    }
}

public final class SwiftFileProcessingWalker: SyntaxAnyVisitor {
    
    public override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        if node is DeclSyntaxProtocol {
            
        }
        return .skipChildren
    }
    
    func visitCodeContainer<S: CustomCodeContainerSyntaxProtocol & DeclSyntaxProtocol & CustomNamedDeclSyntax>(_ node: S) {
        CodeContainerSyntax(syntaxNode: node)
    }
    
    func visitCode<S: CustomCodeSyntaxProtocol & SyntaxProtocol & CustomNamedDeclSyntax>(_ node: S) {
        CodeSyntax(syntaxNode: node)
    }
    
    public init(viewMode: SyntaxTreeViewMode = .sourceAccurate, syntax: SyntaxProtocol) {
        
    }
}


