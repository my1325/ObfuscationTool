//
//  OCFileProcessingPlugin.swift
//  Plugins
//
//  Created by Codex on 2026/2/28.
//

import CodeProtocol
import Foundation
import PathKit
import ProcessingFiles

open class OCFileProcessingPlugin: ProcessingFilePlugin {
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
    }

    private let handlers: [(String) -> String]
    public init(_ mode: [HandleMode]) {
        let camelToSnakeRegex = OCFileProcessingPlugin.camelToSnakeRegex
        handlers = mode.map { mode in
            switch mode {
            case let .replace(prefixOnly, originString, replaceString):
                return { token in
                    if !prefixOnly {
                        return token.replacingOccurrences(of: originString, with: replaceString)
                    }
                    guard token.hasPrefix(originString),
                          let range = token.range(of: originString)
                    else { return token }
                    return token.replacingCharacters(in: range, with: replaceString)
                }
            case let .camelToSnake(handlePrefix, toLowercase):
                return { token in
                    guard token.hasPrefix(handlePrefix) else { return token }
                    let replaced = token.replacingOccurrences(of: handlePrefix, with: "_PREFIX_")
                    let transformed = camelToSnakeRegex.stringByReplacingMatches(
                        in: replaced,
                        range: NSRange(replaced.startIndex..<replaced.endIndex, in: replaced),
                        withTemplate: "$1_$2"
                    )
                    if toLowercase {
                        return transformed.lowercased()
                            .replacingOccurrences(of: "_prefix_", with: handlePrefix)
                    }
                    return transformed.capitalized
                        .replacingOccurrences(of: "_Prefix_", with: handlePrefix)
                }
            case let .snakeToCamel(handlePrefix, toLowercase):
                return { token in
                    guard token.hasPrefix(handlePrefix) else { return token }
                    if token.count(where: { $0 == "_" }) == 1 { return token }
                    let replaced = token.replacingOccurrences(of: handlePrefix, with: "PREFIX_")
                    var parts = replaced.components(separatedBy: "_")
                    let first = toLowercase ? 2 : 1
                    if parts.count > first {
                        for i in first ..< parts.count {
                            guard !parts[i].isEmpty else { continue }
                            parts[i] = parts[i].prefix(1).uppercased() + parts[i].dropFirst()
                        }
                    }
                    return parts.joined().replacingOccurrences(of: "PREFIX", with: handlePrefix)
                }
            }
        }
    }

    public func processingManager(
        _ manager: ProcessingManager,
        processedFile file: Path
    ) throws -> [CodeRawProtocol] {
        let source: String = try file.read()
        let output = processSource(source)
        return [
            Code(
                type: .line,
                words: [CodeRawWord(identifier: .word, content: output)],
                rawName: ""
            )
        ]
    }

    public func processingManager(
        _ manager: ProcessingManager,
        didProcessedFile file: ProcessingFile
    ) throws -> ProcessingFile {
        file
    }

    public func processingManager(
        _ manager: ProcessingManager,
        completedProcessFile files: [ProcessingFile]
    ) throws -> [ProcessingFile] {
        files
    }

    private func processSource(_ source: String) -> String {
        var result = ""
        result.reserveCapacity(source.count)
        var token = ""
        token.reserveCapacity(64)

        var index = source.startIndex
        var inLineComment = false
        var inBlockComment = false
        var inDoubleQuote = false
        var inSingleQuote = false

        func flushToken() {
            guard !token.isEmpty else { return }
            let newToken = handlers.reduce(token) { current, handler in
                handler(current)
            }
            result.append(contentsOf: newToken)
            token = ""
        }

        while index < source.endIndex {
            let ch = source[index]
            let nextIndex = source.index(after: index)
            let nextChar: Character? = nextIndex < source.endIndex ? source[nextIndex] : nil

            if inLineComment {
                result.append(ch)
                if ch == "\n" { inLineComment = false }
                index = nextIndex
                continue
            }

            if inBlockComment {
                result.append(ch)
                if ch == "*", nextChar == "/" {
                    result.append("/")
                    index = source.index(after: nextIndex)
                    inBlockComment = false
                } else {
                    index = nextIndex
                }
                continue
            }

            if inDoubleQuote {
                result.append(ch)
                if ch == "\\" {
                    if let nextChar {
                        result.append(nextChar)
                        index = source.index(after: nextIndex)
                    } else {
                        index = nextIndex
                    }
                } else {
                    if ch == "\"" { inDoubleQuote = false }
                    index = nextIndex
                }
                continue
            }

            if inSingleQuote {
                result.append(ch)
                if ch == "\\" {
                    if let nextChar {
                        result.append(nextChar)
                        index = source.index(after: nextIndex)
                    } else {
                        index = nextIndex
                    }
                } else {
                    if ch == "'" { inSingleQuote = false }
                    index = nextIndex
                }
                continue
            }

            if ch == "/", nextChar == "/" {
                flushToken()
                result.append("/")
                result.append("/")
                index = source.index(after: nextIndex)
                inLineComment = true
                continue
            }

            if ch == "/", nextChar == "*" {
                flushToken()
                result.append("/")
                result.append("*")
                index = source.index(after: nextIndex)
                inBlockComment = true
                continue
            }

            if ch == "\"" {
                flushToken()
                inDoubleQuote = true
                result.append(ch)
                index = nextIndex
                continue
            }

            if ch == "'" {
                flushToken()
                inSingleQuote = true
                result.append(ch)
                index = nextIndex
                continue
            }

            if ch.isOCIdentifierChar {
                token.append(ch)
            } else {
                flushToken()
                result.append(ch)
            }
            index = nextIndex
        }

        flushToken()
        return result
    }
}

private extension Character {
    var isOCIdentifierChar: Bool {
        isLetter || isNumber || self == "_"
    }
}

private extension OCFileProcessingPlugin {
    static let camelToSnakeRegex: NSRegularExpression = {
        // 把 fooBar -> foo_Bar（之后再整体 lowercased/capitalized）
        try! NSRegularExpression(pattern: "([a-z])([A-Z])", options: [])
    }()
}
