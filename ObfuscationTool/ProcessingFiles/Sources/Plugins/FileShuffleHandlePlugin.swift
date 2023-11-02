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
    
    public func processingPlugin(_ plugin: SwiftFileProcessingPlugin, didProcessedFiles file: ProcessingFile) -> ProcessingFile {
        shuffledFile(file)
    }
    
    public func processingPlugin(_ plugin: SwiftFileProcessingPlugin, didCompleteProcessedFiles files: [ProcessingFile]) -> [ProcessingFile] {
        files
    }
    
    func shuffledFile(_ file: ProcessingFile) -> ProcessingFile {
        var codes = file.codes.map(shuffledCode)
        if order {
            codes = groupeCode(codes.sorted(by: { $0.order < $1.order }))
                .map({ $0.shuffled() })
                .flatMap({ $0 })
        } else {
            codes = codes.shuffled()
        }
        return file.newFileWithCode(codes)
    }
    
    func shuffledCode(_ code: CodeRawProtocol) -> CodeRawProtocol {
        if let codeContainer = code as? CodeContainerProtocol, codeContainer.type != .struct {
            return shuffledCodeContaier(codeContainer)
        }
        return code
    }
    
    func shuffledCodeContaier(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol {
        let newCodeContainer = codeContainer
            .mapCodeContainer(block: shuffledCodeContaier)
            .asCodeContainer()
        
        let enumCaseCondition: (CodeRawProtocol) -> Bool = {
            if let code = $0 as? CodeProtocol {
                return code.type == .enumCase
            }
            return false
        }
        
        var codes = codeContainer.code
        let enumCaseCode = codes.filter(enumCaseCondition)
        codes.removeAll(where: enumCaseCondition)
        
        var newCode: [CodeRawProtocol] = codes
        if order {
            newCode = groupeCode(newCode.sorted(by: { $0.order < $1.order }))
                .map({ $0.shuffled() })
                .flatMap({ $0 })
        } else {
            newCode = newCode.shuffled()
        }
        newCode += enumCaseCode
        return newCodeContainer.newCode(newCode, newDeclareWord: newCodeContainer.entireDeclareWord)
    }
    
    func groupeCode(_ code: [CodeRawProtocol]) -> [[CodeRawProtocol]] {
        var retValue: [[CodeRawProtocol]] = Array<[CodeRawProtocol]>(repeating: [], count: code.count)
        var length = 0
        for e in code {
            var i = 0
            while i < length {
                let subValue = retValue[i]
                if e.order == subValue[0].order { break }
                i += 1
            }
            var subValue = retValue[i]
            subValue.append(e)
            retValue[i] = subValue
            if i == length { length += 1 }
        }
        return retValue.prefix(upTo: length).map({ $0 })
    }
}
