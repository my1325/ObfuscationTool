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
import PathKit

public protocol SwiftFileProcessingHandlePluginProtocol {
    func processingPlugin(
        _ plugin: SwiftFileProcessingPlugin,
        didProcessedFiles file: ProcessingFile
    ) -> ProcessingFile
    
    func processingPlugin(
        _ plugin: SwiftFileProcessingPlugin,
        didCompleteProcessedFiles files: [ProcessingFile]
    ) -> [ProcessingFile]
}

open class SwiftFileProcessingPlugin: ProcessingFilePlugin {
    
    let plugins: [SwiftFileProcessingHandlePluginProtocol]
    public init(plugins: [SwiftFileProcessingHandlePluginProtocol]) {
        self.plugins = plugins
    }
        
    public func processingManager(
        _ manager: ProcessingManager,
        processedFile file: Path
    ) throws -> [CodeRawProtocol] {
        let source: String = try file.read()
        var parser = Parser(source)
        let fileSyntax = SourceFileSyntax.parse(from: &parser)
        let walker = SwiftSyntaxWalker(syntaxNode: fileSyntax)
        return walker.walk().map(\.asRawCode)
    }
    
    public func processingManager(
        _ manager: ProcessingManager,
        didProcessedFile file: ProcessingFile
    ) throws -> ProcessingFile {
        plugins.reduce(file, { $1.processingPlugin(self, didProcessedFiles: $0) })
    }
    
    public func processingManager(
        _ manager: ProcessingManager,
        completedProcessFile files: [ProcessingFile]
    ) throws -> [ProcessingFile] {
        plugins.reduce(files, { $1.processingPlugin(self, didCompleteProcessedFiles: $0) })
    }
}
