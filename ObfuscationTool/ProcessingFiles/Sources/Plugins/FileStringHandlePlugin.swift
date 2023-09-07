//
//  File.swift
//  
//
//  Created by mayong on 2023/9/7.
//

import Foundation
import ProcessingFiles
import CodeProtocol

open class FileStringHandlePlugin: ProcessingFileHandlePlugin {

    public enum HandleMode {
        public enum PrefixMode {
            case add
            case replace
            case addOrReplace
        }
        case prefix(mode: PrefixMode, prefix: String, separator: Character)
        case replace(newString: String, replaceString: String)
        
        func handler(_ codeType: [CodeType], codeContainerType: [CodeContainerType]) -> FileStringPrefixModeHandler {
            switch self {
            case let .prefix(mode, prefix, separator): return FileStringHandlePrefix(mode: mode,
                                                                                     prefix: prefix,
                                                                                     separator: separator,
                                                                                     supportCodeType: codeType,
                                                                                     supportCodeContainerType: codeContainerType)
            case let .replace(newString, replaceString): fatalError()
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
        self.handlers = mode.map({ $0.handler(codeType, codeContainerType: codeContainerType) })
    }
    
    public func processingManager(_ manager: ProcessingManager, didProcessedFiles files: [ProcessingFile]) -> [ProcessingFile] {
        let allCode = files.map({ $0.codes })
            .map(extactCode)
            .flatMap({ $0 })
            .filter({
                if let code = $0 as? CodeProtocol, self.shouldHandleCode(code.type) {
                    return true
                } else if let code = $0 as? CodeContainerProtocol, self.shouldHandleCodeContainer(code.type) {
                    return true
                } else {
                    return false
                }
            })
        handlers.forEach({ $0.prepareWithAllCode(allCode) })
        return files.map(handleFile)
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
        } else if let code = rawCode as? CodeContainerProtocol, shouldHandleCodeContainer(code.type) {
            return handleCodeContainer(code)
        } else {
            return rawCode
        }
    }
    
    private func handleCode(_ code: CodeProtocol) -> CodeProtocol {
        handlers.reduce(code, { $1.handleCode(code) })
    }
    
    private func handleCodeContainer(_ code: CodeContainerProtocol) -> CodeContainerProtocol {
        handlers.reduce(code, { $1.handleCodeContainer(code) })
    }
}

public protocol FileStringPrefixModeHandler {
    func prepareWithAllCode(_ allCode: [CodeRawProtocol])
    
    func handleCode(_ code: CodeProtocol) -> CodeProtocol
    
    func handleCodeContainer(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol
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
        allCode.map({ $0.rawName })
            .filter({ !$0.isEmpty })
            .forEach(handleName)
        print(cacheHandledString)
    }
    
    public func handleCode(_ code: CodeProtocol) -> CodeProtocol {
        let name = cacheHandledString[code.rawName] ?? code.rawName
        let content = code.content
            .components(separatedBy: " ")
            .map({ cacheHandledString.reduce($0, { $0.replacingOccurrences(of: $1.key, with: $1.value) }) })
            .joined(separator: " ")
        return Code(type: code.type, content: content, rawName: name)
    }
    
    public func handleCodeContainer(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol {
        let name = cacheHandledString[codeContainer.rawName] ?? codeContainer.rawName
        let declare = codeContainer.entireDeclare
            .components(separatedBy: " ")
            .map({ cacheHandledString.reduce($0, { $0.replacingOccurrences(of: $1.key, with: $1.value) }) })
            .joined(separator: " ")
        let newContainer = CodeContainer(type: codeContainer.type, entireDeclare: declare, code: codeContainer.code, rawName: name)
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
