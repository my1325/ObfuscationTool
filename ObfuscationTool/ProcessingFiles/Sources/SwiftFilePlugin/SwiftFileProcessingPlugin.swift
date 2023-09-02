//
//  File.swift
//  
//
//  Created by my on 2023/9/2.
//

import Foundation
import SwiftSyntax
import ProcessingFiles
import FilePath

open class SwiftFileProcessingPlugin: ProcessingFilePlugin {
    public init() { }
    
    public func processingManager(_ manager: ProcessingManager, processedFile file: FilePath) throws -> ProcessingFile {
        try SwiftProcessingFile.parseFileAtPath(file)
    }
}
