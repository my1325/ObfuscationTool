//
//  File.swift
//
//
//  Created by mayong on 2023/9/7.
//

import CodeProtocol
import Foundation
import ProcessingFiles
import SwiftFilePlugin

open class FileStringHandlePlugin: SwiftFileProcessingHandlePluginProtocol {
    public enum HandleMode {
        public enum PrefixMode {
            case add
            case replace
            case addOrReplace
        }

        case prefix(mode: PrefixMode, prefix: String, separator: Character)
        case replace(originString: String, replaceString: String)
        
        func handler(_ codeType: [CodeType], codeContainerType: [CodeContainerType]) -> FileStringPrefixModeHandler {
            switch self {
            case let .prefix(mode, prefix, separator):
                return FileStringHandlePrefix(mode: mode,
                                              prefix: prefix,
                                              separator: separator,
                                              supportCodeType: codeType,
                                              supportCodeContainerType: codeContainerType)
            case let .replace(originString, replaceString):
                return FileStringReplace(origin: originString,
                                         replace: replaceString,
                                         supportCodeType: codeType,
                                         supportCodeContainerType: codeContainerType)
            }
        }
    }
    
    public let mode: [HandleMode]
    public let codeType: [CodeType]
    public let codeContainerType: [CodeContainerType]
    public let handlers: [FileStringPrefixModeHandler]
    public init(_ mode: [HandleMode], codeType: [CodeType] = [], codeContainerType: [CodeContainerType] = []) {
        self.mode = mode
        self.codeType = codeType
        self.codeContainerType = codeContainerType
        self.handlers = mode.map { $0.handler(codeType, codeContainerType: codeContainerType) }
    }
    
    public func processingPlugin(_ plugin: SwiftFileProcessingPlugin, didProcessedFiles file: ProcessingFile) -> ProcessingFile {
        let fileCode = extactCode(file.codes)
            .filter {
                if let code = $0 as? CodeProtocol, self.shouldHandleCode(code.type) {
                    return true
                } else if let code = $0 as? CodeContainerProtocol, self.shouldHandleCodeContainer(code.type) {
                    return true
                } else {
                    return false
                }
            }
        handlers.forEach { $0.prepareWithAllCode(fileCode) }
        return file
    }
    
    public func processingPlugin(_ plugin: SwiftFileProcessingPlugin, didCompleteProcessedFiles files: [ProcessingFile]) -> [ProcessingFile] {
        files.map(handleFile)
    }
    
    private func extactCode(_ code: [CodeRawProtocol]) -> [CodeRawProtocol] {
        var retValue: [CodeRawProtocol] = []
        for aCode in code {
            if aCode.isCode {
                retValue.append(aCode)
            } else if let aContainer = aCode as? CodeContainerProtocol {
                retValue.append(aCode)
                retValue.append(contentsOf: extactCode(aContainer.code))
            }
        }
        return retValue
    }
    
    private func handleFile(_ file: ProcessingFile) -> ProcessingFile {
        file.newFileWithCode(file.codes.map(handleCode))
    }
    
    private func shouldHandleCode(_ type: CodeType) -> Bool {
        codeType.isEmpty || codeType.contains(type)
    }
    
    private func shouldHandleCodeContainer(_ type: CodeContainerType) -> Bool {
        codeContainerType.isEmpty || codeContainerType.contains(type)
    }
    
    private func handleCode(_ rawCode: CodeRawProtocol) -> CodeRawProtocol {
        if let code = rawCode as? CodeProtocol, shouldHandleCode(code.type) {
            return handleCode(code)
        } else if let code = rawCode as? CodeContainerProtocol {
            if shouldHandleCodeContainer(code.type) {
                return handleCodeContainer(code)
            } else {
                return CodeContainer(type: code.type,
                                     entireDeclareWord: code.entireDeclareWord,
                                     code: code.code.map(handleCode),
                                     rawName: code.rawName)
            }
        } else {
            return rawCode
        }
    }
    
    private func handleCode(_ code: CodeProtocol) -> CodeProtocol {
        handlers.reduce(code) { $1.handleCode($0) }
    }
    
    private func handleCodeContainer(_ code: CodeContainerProtocol) -> CodeContainerProtocol {
        handlers.reduce(code) { $1.handleCodeContainer($0) }
    }
}

public protocol FileStringPrefixModeHandler {
    func prepareWithAllCode(_ allCode: [CodeRawProtocol])
    
    func handleCode(_ code: CodeProtocol) -> CodeProtocol
    
    func handleCodeContainer(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol
}

open class FileStringReplace: FileStringPrefixModeHandler {
    let origin: String
    let replace: String
    let supportCodeType: [CodeType]
    let supportCodeContainerType: [CodeContainerType]
    init(origin: String,
         replace: String,
         supportCodeType: [CodeType],
         supportCodeContainerType: [CodeContainerType])
    {
        self.origin = origin
        self.replace = replace
        self.supportCodeType = supportCodeType
        self.supportCodeContainerType = supportCodeContainerType
    }
    
    public func prepareWithAllCode(_ allCode: [CodeRawProtocol]) {}
    
    public func handleCode(_ code: CodeProtocol) -> CodeProtocol {
        let name = code.rawName.replacingOccurrences(of: origin, with: replace)
        let words = code.words
            .map {
                if $0.identifier == .identifier {
                    let newContent = $0.content.replacingOccurrences(of: origin, with: replace)
                    return $0.newWord(newContent)
                }
                return $0
            }
        return Code(type: code.type, words: words, rawName: name)
    }
    
    public func handleCodeContainer(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol {
        let name = codeContainer.rawName.replacingOccurrences(of: origin, with: replace)
        let declareWord = codeContainer.entireDeclareWord
            .map {
                if $0.identifier == .identifier {
                    let newContent = $0.content.replacingOccurrences(of: origin, with: replace)
                    return $0.newWord(newContent)
                }
                return $0
            }
        
        let newContainer = CodeContainer(type: codeContainer.type, entireDeclareWord: declareWord, code: codeContainer.code, rawName: name)
        return newContainer.mapCode(supportCodeType, block: handleCode)
            .mapCodeContainer(supportCodeContainerType, block: handleCodeContainer)
            .asCodeContainer()
    }
}

open class FileStringHandlePrefix: FileStringPrefixModeHandler {
    var cacheHandledString: [String: String] = [:]
    let mode: FileStringHandlePlugin.HandleMode.PrefixMode
    let prefix: String
    let separator: Character
    let supportCodeType: [CodeType]
    let supportCodeContainerType: [CodeContainerType]
    init(mode: FileStringHandlePlugin.HandleMode.PrefixMode,
         prefix: String,
         separator: Character,
         supportCodeType: [CodeType],
         supportCodeContainerType: [CodeContainerType])
    {
        self.mode = mode
        self.prefix = prefix
        self.separator = separator
        self.supportCodeType = supportCodeType
        self.supportCodeContainerType = supportCodeContainerType
    }
    
    public func prepareWithAllCode(_ allCode: [CodeRawProtocol]) {
        allCode.map { $0.rawName.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .forEach(handleName)
    }
    
    public func handleCode(_ code: CodeProtocol) -> CodeProtocol {
        let name = cacheHandledString[code.rawName] ?? code.rawName
        let words = code.words
            .map {
                let key = $0.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if $0.identifier == .identifier, let contentNeedToReplace = cacheHandledString[key] {
                    let newContent = $0.content.replacingOccurrences(of: key, with: contentNeedToReplace)
                    return $0.newWord(newContent)
                }
                return $0
            }
        return Code(type: code.type, words: words, rawName: name)
    }
    
    public func handleCodeContainer(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol {
        let name = cacheHandledString[codeContainer.rawName] ?? codeContainer.rawName
        let declareWord = codeContainer.entireDeclareWord
            .map {
                let key = $0.content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if $0.identifier == .identifier, let contentNeedToReplace = cacheHandledString[key] {
                    let newContent = $0.content.replacingOccurrences(of: key, with: contentNeedToReplace)
                    return $0.newWord(newContent)
                }
                return $0
            }
        
        let newContainer = CodeContainer(type: codeContainer.type, entireDeclareWord: declareWord, code: codeContainer.code, rawName: name)
        return newContainer.mapCode(supportCodeType, block: handleCode)
            .mapCodeContainer(supportCodeContainerType, block: handleCodeContainer)
            .asCodeContainer()
    }
    
    private func handleName(_ rawName: String) {
        let replacePrefix = String(format: "%@%@", prefix, String(separator))
        let result: String
        defer { cacheHandledString[rawName] = result }
        switch mode {
        case .add: result = addPrefixIfNotHas(replacePrefix, rawName: rawName)
        case .replace: result = replacePrefixIfHas(replacePrefix, rawName: rawName)
        case .addOrReplace: result = replaceOrAdd(replacePrefix, rawName: rawName)
        }
    }
    
    private func addPrefixIfNotHas(_ prefix: String, rawName: String) -> String {
        if !rawName.hasPrefix(prefix) {
            return String(format: "%@%@", prefix, rawName)
        }
        return rawName
    }
    
    private func replacePrefixIfHas(_ prefix: String, rawName: String) -> String {
        if let index = rawName.firstIndex(of: separator) {
            let range = rawName.startIndex ... index
            return rawName.replacingCharacters(in: range, with: prefix)
        }
        return rawName
    }
    
    private func replaceOrAdd(_ prefix: String, rawName: String) -> String {
        if let index = rawName.firstIndex(of: separator) {
            let range = rawName.startIndex ... index
            return rawName.replacingCharacters(in: range, with: prefix)
        }
        if !rawName.hasPrefix(prefix) {
            return String(format: "%@%@", prefix, rawName)
        }
        return rawName
    }
}
