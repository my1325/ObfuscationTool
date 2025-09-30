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
        case replace(
            prefixOnly: Bool,
            originString: String,
            replaceString: String
        )

        case camelToSnake(
            handlePrefix: String,
            toLowercase: Bool
        )

        case snakeToCamel(
            handlePrefix: String,
            toLowercase: Bool
        )

        func handler(
            _ codeType: [CodeType],
            codeContainerType: [CodeContainerType]
        ) -> FileStringPrefixModeHandler {
            switch self {
                case let .replace(prefixOnly, originString, replaceString):
                    FileStringReplace(
                        onlyPrefix: prefixOnly,
                        origin: originString,
                        replace: replaceString,
                        supportCodeType: codeType,
                        supportCodeContainerType: codeContainerType
                    )
                case let .camelToSnake(handlePrefix, toLowercase):
                    FileStringCamelToSnake(
                        handlePrefix: handlePrefix,
                        supportCodeType: codeType,
                        supportCodeContainerType: codeContainerType,
                        toLowercase: toLowercase
                    )
                case let .snakeToCamel(handlePrefix, toLowercase):
                    FileStringSnakeToCamel(
                        handlePrefix: handlePrefix,
                        supportCodeType: codeType,
                        supportCodeContainerType: codeContainerType,
                        toLowercase: toLowercase
                    )
            }
        }
    }

    public let codeType: [CodeType]
    public let codeContainerType: [CodeContainerType]
    public let handlers: [FileStringPrefixModeHandler]
    public init(
        _ mode: [HandleMode],
        codeType: [CodeType] = [],
        codeContainerType: [CodeContainerType] = []
    ) {
        self.codeType = codeType
        self.codeContainerType = codeContainerType
        self.handlers = mode.map {
            $0.handler(
                codeType,
                codeContainerType: codeContainerType
            )
        }
    }

    public func processingPlugin(
        _ plugin: SwiftFileProcessingPlugin,
        didProcessedFiles file: ProcessingFile
    ) -> ProcessingFile {
        let fileCode = extactCode(file.codes)
            .filter {
                if let code = $0 as? CodeProtocol {
                    return self.shouldHandleCode(code.type)
                }

                if let code = $0 as? CodeContainerProtocol {
                    return self.shouldHandleCodeContainer(code.type)
                }

                return false
            }
        handlers.forEach { $0.prepareWithAllCode(fileCode) }
        return file
    }

    public func processingPlugin(
        _ plugin: SwiftFileProcessingPlugin,
        didCompleteProcessedFiles files: [ProcessingFile]
    ) -> [ProcessingFile] {
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
                return CodeContainer(
                    type: code.type,
                    entireDeclareWord: code.entireDeclareWord,
                    code: code.code.map(handleCode),
                    rawName: code.rawName
                )
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
    let onlyPrefix: Bool
    init(
        onlyPrefix: Bool,
        origin: String,
        replace: String,
        supportCodeType: [CodeType],
        supportCodeContainerType: [CodeContainerType]
    ) {
        self.onlyPrefix = onlyPrefix
        self.origin = origin
        self.replace = replace
        self.supportCodeType = supportCodeType
        self.supportCodeContainerType = supportCodeContainerType
    }

    public func prepareWithAllCode(_ allCode: [CodeRawProtocol]) {}

    func replace(_ name: String) -> String {
        if !onlyPrefix {
            return name.replacingOccurrences(of: origin, with: replace)
        } else if name.hasPrefix(origin), let subRange = name.range(of: origin) {
            return name.replacingCharacters(in: subRange, with: replace)
        } else {
            return name
        }
    }

    func replace(_ codeWords: [CodeRawWordProtocol]) -> [CodeRawWordProtocol] {
        codeWords.map {
            guard $0.identifier == .identifier else {
                return $0
            }
            return $0.newWord(replace($0.content))
        }
    }

    public func handleCode(_ code: CodeProtocol) -> CodeProtocol {
        Code(
            type: code.type,
            words: replace(code.words),
            rawName: replace(code.rawName)
        )
    }

    public func handleCodeContainer(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol {
        CodeContainer(
            type: codeContainer.type,
            entireDeclareWord: replace(codeContainer.entireDeclareWord),
            code: codeContainer.code,
            rawName: replace(codeContainer.rawName)
        )
        .mapCode(
            supportCodeType,
            block: handleCode
        )
        .mapCodeContainer(
            supportCodeContainerType,
            block: handleCodeContainer
        )
        .asCodeContainer()
    }
}

open class FileStringCamelToSnake: FileStringPrefixModeHandler {
    let handlePrefix: String
    let supportCodeType: [CodeType]
    let supportCodeContainerType: [CodeContainerType]
    let toLowercase: Bool
    init(
        handlePrefix: String,
        supportCodeType: [CodeType],
        supportCodeContainerType: [CodeContainerType],
        toLowercase: Bool
    ) {
        self.handlePrefix = handlePrefix
        self.supportCodeType = supportCodeType
        self.supportCodeContainerType = supportCodeContainerType
        self.toLowercase = toLowercase
    }

    public func prepareWithAllCode(_ allCode: [CodeRawProtocol]) {}

    func camelToSnake(_ name: String) -> String {
        name.components(separatedBy: .newlines)
            .map {
                guard $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(handlePrefix) else {
                    return $0
                }

                let string = $0.replacingOccurrences(of: handlePrefix, with: "_PREFIX_")
                let line = string.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1_$2", options: .regularExpression)
                if toLowercase {
                    return line.lowercased()
                        .replacingOccurrences(of: "_prefix_", with: handlePrefix)
                }
                return line.capitalized
                    .replacingOccurrences(of: "_Prefix_", with: handlePrefix)
            }
            .joined(separator: "\n")
    }

    func camelToSnake(_ codeWords: [CodeRawWordProtocol]) -> [CodeRawWordProtocol] {
        codeWords.map {
            guard $0.identifier == .identifier else {
                return $0
            }
            return $0.newWord(camelToSnake($0.content))
        }
    }

    public func handleCode(_ code: CodeProtocol) -> CodeProtocol {
        Code(
            type: code.type,
            words: camelToSnake(code.words),
            rawName: camelToSnake(code.rawName)
        )
    }

    public func handleCodeContainer(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol {
        CodeContainer(
            type: codeContainer.type,
            entireDeclareWord: camelToSnake(codeContainer.entireDeclareWord),
            code: codeContainer.code.map {
                if let rawCode = $0 as? CodeProtocol {
                    return handleCode(rawCode)
                }
                if let rawContainer = $0 as? CodeContainerProtocol {
                    return handleCodeContainer(rawContainer)
                }
                return $0
            },
            rawName: camelToSnake(codeContainer.rawName)
        )
        .mapCode(
            supportCodeType,
            block: handleCode
        )
        .mapCodeContainer(
            supportCodeContainerType,
            block: handleCodeContainer
        )
        .asCodeContainer()
    }
}

open class FileStringSnakeToCamel: FileStringPrefixModeHandler {
    let handlePrefix: String
    let supportCodeType: [CodeType]
    let supportCodeContainerType: [CodeContainerType]
    let toLowercase: Bool
    init(
        handlePrefix: String,
        supportCodeType: [CodeType],
        supportCodeContainerType: [CodeContainerType],
        toLowercase: Bool
    ) {
        self.handlePrefix = handlePrefix
        self.supportCodeType = supportCodeType
        self.supportCodeContainerType = supportCodeContainerType
        self.toLowercase = toLowercase
    }

    public func prepareWithAllCode(_ allCode: [CodeRawProtocol]) {}

    func snakeToCamel(_ name: String) -> String {
        name.components(separatedBy: .newlines)
            .map {
                guard $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(handlePrefix) else {
                    return $0
                }

                if $0.count(where: { $0 == "_" }) == 1 {
                    return $0
                }

                let string = $0.replacingOccurrences(of: handlePrefix, with: "PREFIX_")
                //                let line = string.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1_$2", options: .regularExpression)
                // snake to camel
                var line = string.components(separatedBy: "_")
                let first = toLowercase ? 2 : 1
                for i in first ..< line.count {
                    let part = line[i]
                    if part.isEmpty { continue }
                    line[i] = part.prefix(1).uppercased() + part.dropFirst()
                }
                return line.joined()
                    .replacingOccurrences(of: "PREFIX", with: handlePrefix)
            }
            .joined(separator: "\n")
    }

    func snakeToCamel(_ codeWords: [CodeRawWordProtocol]) -> [CodeRawWordProtocol] {
        codeWords.map {
            guard $0.identifier == .identifier else {
                return $0
            }
            return $0.newWord(snakeToCamel($0.content))
        }
    }

    public func handleCode(_ code: CodeProtocol) -> CodeProtocol {
        Code(
            type: code.type,
            words: snakeToCamel(code.words),
            rawName: snakeToCamel(code.rawName)
        )
    }

    public func handleCodeContainer(_ codeContainer: CodeContainerProtocol) -> CodeContainerProtocol {
        CodeContainer(
            type: codeContainer.type,
            entireDeclareWord: snakeToCamel(codeContainer.entireDeclareWord),
            code: codeContainer.code.map {
                if let rawCode = $0 as? CodeProtocol {
                    return handleCode(rawCode)
                }
                if let rawContainer = $0 as? CodeContainerProtocol {
                    return handleCodeContainer(rawContainer)
                }
                return $0
            },
            rawName: snakeToCamel(codeContainer.rawName)
        )
        .mapCode(
            supportCodeType,
            block: handleCode
        )
        .mapCodeContainer(
            supportCodeContainerType,
            block: handleCodeContainer
        )
        .asCodeContainer()
    }
}
