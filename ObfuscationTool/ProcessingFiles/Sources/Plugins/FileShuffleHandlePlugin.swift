//
//  File.swift
//  
//
//  Created by mayong on 2023/9/8.
//

import CodeProtocol
import Foundation
import ProcessingFiles
import SwiftFilePlugin

open class FileShuffleHandlePlugin: SwiftFileProcessingHandlePluginProtocol {
    
    public let order: Bool
    public init(order: Bool = false) {
        self.order = order
    }
    
    public func processingPlugin(
        _ plugin: SwiftFileProcessingPlugin,
        didProcessedFiles file: ProcessingFile
    ) -> ProcessingFile {
        shuffledFile(file)
    }
    
    public func processingPlugin(
        _ plugin: SwiftFileProcessingPlugin,
        didCompleteProcessedFiles files: [ProcessingFile]
    ) -> [ProcessingFile] {
        files
    }
    
    func shuffledFile(_ file: ProcessingFile) -> ProcessingFile {
        file.newFileWithCode(
            shuffled(file.codes.map(shuffledCode))
        )
    }
    
    func shuffledCode(_ code: CodeRawProtocol) -> CodeRawProtocol {
        if let codeContainer = code as? CodeContainerProtocol, 
            codeContainer.type != .struct
        {
            return shuffledCodeContaier(codeContainer)
        }
        return code
    }
    
    func shuffledCodeContaier(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol {
        let newCodeContainer = codeContainer
            .mapCodeContainer(block: shuffledCodeContaier)
            .asCodeContainer()
        
        let enumCaseFilter: (inout [CodeRawProtocol]) -> [CodeRawProtocol] = {
            let enumCaseCodes = $0.compactMap { $0.asCode(.enumCase) }
            $0.removeAll {
                if let code = $0 as? CodeProtocol {
                    return code.type == .enumCase
                }
                return false
            }
            return enumCaseCodes
        }
        
        var codes = codeContainer.code
        let enumCaseCode = enumCaseFilter(&codes)
        
        return newCodeContainer.newCode(
            shuffled(codes) + enumCaseCode,
            newDeclareWord: newCodeContainer.entireDeclareWord
        )
    }
    
    func shuffled(_ codes: [CodeRawProtocol]) -> [CodeRawProtocol] {
        if order {
            return groupCode(codes)
                .map({ $0.shuffled() })
                .flatMap({ $0 })
        } else {
            return codes.shuffled()
        }
    }
    
    func groupCode(_ code: [CodeRawProtocol]) -> [[CodeRawProtocol]] {
        Dictionary(grouping: code, by: \.order)
            .map { ($0, $1) }
            .sorted(by: { $0.0 < $1.0 })
            .map(\.1)
    }
}
