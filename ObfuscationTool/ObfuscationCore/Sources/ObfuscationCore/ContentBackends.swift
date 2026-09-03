import Foundation
import PathKit
import ProcessingFiles
import SwiftFilePlugin
import Plugins
import CodeProtocol
import SwiftParser
import SwiftSyntax

public enum ContentBackendError: Error, CustomStringConvertible {
    case unsupportedFileType(String)
    case stringEncodingFailed

    public var description: String {
        switch self {
        case let .unsupportedFileType(ext): return "Unsupported file type: \(ext)"
        case .stringEncodingFailed: return "String encoding failed"
        }
    }
}

public struct ContentProcessor: Sendable {
    public init() {}

    /// `*.xcassets` 下的 `Contents.json`（Xcode 资源目录，文件名大小写不敏感）。
    private func isAssetCatalogContentsJSON(_ path: Path) -> Bool {
        guard path.lastComponent.lowercased() == "contents.json" else { return false }
        return path.components.contains { $0.lowercased().hasSuffix(".xcassets") }
    }

    public func process(
        path: Path,
        data: Data,
        rules: [Rule]
    ) throws -> Data {
        let activeContentRules = rules.filter { $0.enabled && $0.appliesTo.contains(.content) }
        let activeShuffleRules = rules.filter { $0.enabled && $0.appliesTo.contains(.swiftStructure) }

        let ext = (path.extension ?? "").lowercased()
        switch ext {
        case "swift":
            return try processSwift(path: path, data: data, contentRules: activeContentRules, shuffleRules: activeShuffleRules)
        case "h", "m":
            return try processOC(data: data, rules: activeContentRules)
        case "strings":
            return try processPlainText(data: data, rules: activeContentRules)
        case "json":
            if isAssetCatalogContentsJSON(path) {
                let rulesForJSON = rules.filter {
                    $0.enabled && ($0.appliesTo.contains(.content) || $0.appliesTo.contains(.path))
                }
                return try processPlainText(data: data, rules: rulesForJSON)
            }
            return data
        default:
            return data
        }
    }

    private func processSwift(
        path: Path,
        data: Data,
        contentRules: [Rule],
        shuffleRules: [Rule]
    ) throws -> Data {
        guard let source = String(data: data, encoding: .utf8) else {
            return data
        }

        var parser = Parser(source)
        let fileSyntax = SourceFileSyntax.parse(from: &parser)
        let walker = SwiftSyntaxWalker(syntaxNode: fileSyntax)
        let codes: [CodeRawProtocol] = walker.walk().map { $0.asRawCode }

        let file = ProcessingFile(filePath: path, fileType: .swift)
        file.setCodes(codes)

        let swiftPlugin = SwiftFileProcessingPlugin(plugins: [])
        var handlePlugins: [SwiftFileProcessingHandlePluginProtocol] = []

        if !contentRules.isEmpty {
            let modes = contentRules.flatMap(ruleToFileStringModes)
            handlePlugins.append(FileStringHandlePlugin(modes))
        }

        if let shuffle = shuffleRules.compactMap(ruleToShuffle).first {
            handlePlugins.append(FileShuffleHandlePlugin(order: shuffle.orderAware))
        }

        var processed = file
        for p in handlePlugins {
            processed = p.processingPlugin(swiftPlugin, didProcessedFiles: processed)
        }
        let completed = handlePlugins.reduce([processed]) { current, plugin in
            plugin.processingPlugin(swiftPlugin, didCompleteProcessedFiles: current)
        }

        let out = try completed.first?.getContent() ?? source
        guard let outData = out.data(using: .utf8) else { throw ContentBackendError.stringEncodingFailed }
        return outData
    }

    private struct ShuffleConfig: Sendable {
        let orderAware: Bool
    }

    private func ruleToShuffle(_ rule: Rule) -> ShuffleConfig? {
        guard rule.enabled else { return nil }
        guard rule.appliesTo.contains(.swiftStructure) else { return nil }
        guard case let .shuffle(orderAware) = rule.kind else { return nil }
        return ShuffleConfig(orderAware: orderAware)
    }

    private func ruleToFileStringModes(_ rule: Rule) -> [FileStringHandlePlugin.HandleMode] {
        guard rule.enabled else { return [] }
        switch rule.kind {
        case let .replace(map):
            return map
                .keys
                .sorted { $0.count > $1.count }
                .map { key in
                    .replace(prefixOnly: rule.scope.onlyPrefix, originString: key, replaceString: map[key] ?? "")
                }
        case let .caseConvert(prefix, toLowercase, direction):
            switch direction {
            case .camelToSnake:
                return [.camelToSnake(handlePrefix: prefix, toLowercase: toLowercase)]
            case .snakeToCamel:
                return [.snakeToCamel(handlePrefix: prefix, toLowercase: toLowercase)]
            }
        case .shuffle:
            return []
        }
    }

    // MARK: - OC / Plain Text

    private func processPlainText(data: Data, rules: [Rule]) throws -> Data {
        guard let source = String(data: data, encoding: .utf8) else { return data }
        let out = applyTextRules(source, rules: rules)
        guard let outData = out.data(using: .utf8) else { throw ContentBackendError.stringEncodingFailed }
        return outData
    }

    private func processOC(data: Data, rules: [Rule]) throws -> Data {
        guard let source = String(data: data, encoding: .utf8) else { return data }
        let handlers = rules.flatMap(ruleToTextHandlers)
        if handlers.isEmpty { return data }
        let out = scanAndTransformLikeOC(source, handlers: handlers)
        guard let outData = out.data(using: .utf8) else { throw ContentBackendError.stringEncodingFailed }
        return outData
    }

    private func applyTextRules(_ source: String, rules: [Rule]) -> String {
        rules.filter(\.enabled).reduce(source) { current, rule in
            switch rule.kind {
            case let .replace(map):
                return map
                    .keys
                    .sorted { $0.count > $1.count }
                    .reduce(current) { str, key in
                        let value = map[key] ?? ""
                        return replaceString(str, key: key, value: value, onlyPrefix: rule.scope.onlyPrefix)
                    }
            case let .caseConvert(prefix, toLowercase, direction):
                switch direction {
                case .camelToSnake:
                    return camelToSnake(current, prefix: prefix, toLowercase: toLowercase)
                case .snakeToCamel:
                    return snakeToCamel(current, prefix: prefix, toLowercase: toLowercase)
                }
            case .shuffle:
                return current
            }
        }
    }

    private func ruleToTextHandlers(_ rule: Rule) -> [(String) -> String] {
        guard rule.enabled else { return [] }
        switch rule.kind {
        case let .replace(map):
            let keys = map.keys.sorted { $0.count > $1.count }
            return keys.map { key in
                { token in
                    self.replaceString(token, key: key, value: map[key] ?? "", onlyPrefix: rule.scope.onlyPrefix)
                }
            }
        case let .caseConvert(prefix, toLowercase, direction):
            switch direction {
            case .camelToSnake:
                return [
                    { token in
                        self.camelToSnake(token, prefix: prefix, toLowercase: toLowercase)
                    },
                ]
            case .snakeToCamel:
                return [
                    { token in
                        self.snakeToCamel(token, prefix: prefix, toLowercase: toLowercase)
                    },
                ]
            }
        case .shuffle:
            return []
        }
    }

    // 复刻现有 OC 插件的扫描策略：跳过注释/字符串，只处理标识符 token（字母/数字/下划线）
    private func scanAndTransformLikeOC(
        _ source: String,
        handlers: [(String) -> String]
    ) -> String {
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

            if ch.isLetter || ch.isNumber || ch == "_" {
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

    private func replaceString(
        _ origin: String,
        key: String,
        value: String,
        onlyPrefix: Bool
    ) -> String {
        if !onlyPrefix {
            return origin.replacingOccurrences(of: key, with: value)
        }
        guard origin.hasPrefix(key), let range = origin.range(of: key) else { return origin }
        return origin.replacingCharacters(in: range, with: value)
    }

    private func camelToSnake(
        _ value: String,
        prefix: String,
        toLowercase: Bool
    ) -> String {
        guard value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(prefix) else { return value }
        let replaced = value.replacingOccurrences(of: prefix, with: "_PREFIX_")
        let withUnderscore = replaced.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1_$2",
            options: .regularExpression
        )
        if toLowercase {
            return withUnderscore.lowercased().replacingOccurrences(of: "_prefix_", with: prefix)
        }
        return withUnderscore.capitalized.replacingOccurrences(of: "_Prefix_", with: prefix)
    }

    private func snakeToCamel(
        _ value: String,
        prefix: String,
        toLowercase: Bool
    ) -> String {
        guard value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(prefix) else { return value }
        if value.count(where: { $0 == "_" }) <= 1 { return value }
        let replaced = value.replacingOccurrences(of: prefix, with: "PREFIX_")
        var parts = replaced.components(separatedBy: "_")
        let first = toLowercase ? 2 : 1
        if parts.count > first {
            for i in first..<parts.count {
                guard !parts[i].isEmpty else { continue }
                parts[i] = parts[i].prefix(1).uppercased() + parts[i].dropFirst()
            }
        }
        return parts.joined().replacingOccurrences(of: "PREFIX", with: prefix)
    }
}

