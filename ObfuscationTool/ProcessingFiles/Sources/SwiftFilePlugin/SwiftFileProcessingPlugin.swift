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
    public init() {}
        
    public func processingManager(_ manager: ProcessingManager, processedFile file: FilePathProtocol) throws -> [CodeRawProtocol] {
        let url = URL(fileURLWithPath: file.path)
        let data = try Data(contentsOf: url)
        guard let source = String(data: data, encoding: .utf8) else {
            throw ProcessingError.fileReadError(file)
        }

        var parser = Parser(source)
        let fileSyntax = SourceFileSyntax.parse(from: &parser)
        let walker = SwiftSyntaxWalker(syntaxNode: fileSyntax)
        return walker.walk().map(\.asRawCode)
    }
}
