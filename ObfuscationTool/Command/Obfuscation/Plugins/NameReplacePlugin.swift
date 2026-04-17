//
//  ResourceFilePlugin.swift
//  Command
//
//  Created by mayong on 2024/9/30.
//

import Foundation
import PathKit
import ProcessingFiles
import ObfuscationCore

open class NameReplacePlugin: ProcessingFilePlugin {
    var onlyFilename: Bool {
        replace.onlyFilename ?? false
    }
    
    var onlyPrefix: Bool {
        replace.onlyPrefix ?? false
    }
    
    var map: [String: String] {
        replace.map ?? [:]
    }
    
    let replace: ObfuscationReplace
    private let transformer = PathTransformer()
    init(_ replace: ObfuscationReplace) {
        self.replace = replace
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
        try files.forEach {
            try $0.newPath(resolvePath($0.filePath))
        }
        return files
    }
    
    open func resolvePath(_ path: Path) throws -> Path {
        let rule = Rule(
            enabled: true,
            appliesTo: [.path],
            scope: .init(onlyPrefix: onlyPrefix, onlyFilename: onlyFilename),
            kind: .replace(map: map)
        )
        return transformer.transform(path, rules: [rule])
    }
    
    func replaceString(
        _ origin: String,
        key: String,
        value: String
    ) -> String {
        if !onlyPrefix {
            return origin.replacingOccurrences(of: key, with: value)
        } else if origin.hasPrefix(key), let subRange = origin.range(of: key) {
            return origin.replacingCharacters(in: subRange, with: value)
        } else {
            return origin
        }
    }
    
    func resolvePathComponent(_ pathComponent: String) -> String {
        map.reduce(pathComponent) {
            replaceString(
                $0,
                key: $1.key,
                value: $1.value
            )
        }
    }
}

open class NameCamelToSnakePlugin: ProcessingFilePlugin {
    let configs: [ObfuscationCamelToSnake]
    let onlyFilename: Bool
    private let transformer = PathTransformer()
    init(_ configs: [ObfuscationCamelToSnake], onlyFilename: Bool) {
        self.configs = configs
        self.onlyFilename = onlyFilename
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
        try files.forEach {
            try $0.newPath(resolvePath($0.filePath))
        }
        return files
    }
    
    open func resolvePath(_ path: Path) throws -> Path {
        let rules: [Rule] = configs.map {
            Rule(
                enabled: true,
                appliesTo: [.path],
                scope: .init(onlyPrefix: false, onlyFilename: onlyFilename),
                kind: .caseConvert(prefix: $0.prefix, toLowercase: $0.toLowercase ?? true, direction: .camelToSnake)
            )
        }
        return transformer.transform(path, rules: rules)
    }
    
    func camelToSnake(_ name: String, config: ObfuscationCamelToSnake) -> String {
        name.components(separatedBy: .newlines)
            .map {
                guard $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(config.prefix) else {
                    return $0
                }
                
                let string = $0.replacingOccurrences(of: config.prefix, with: "_PREFIX_")
                let line = string.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1_$2", options: .regularExpression)
                if config.toLowercase == true {
                    return line.lowercased()
                        .replacingOccurrences(of: "_prefix_", with: config.prefix)
                }
                return line.capitalized
                    .replacingOccurrences(of: "_Prefix_", with: config.prefix)
            }
            .joined(separator: "\n")
    }
    
    func resolvePathComponent(_ pathComponent: String) -> String {
        configs.reduce(pathComponent) {
            camelToSnake(
                $0,
                config: $1
            )
        }
    }
}

open class NameSnakeToCamelPlugin: ProcessingFilePlugin {
    let configs: [ObfuscationCamelToSnake]
    let onlyFilename: Bool
    private let transformer = PathTransformer()
    init(_ configs: [ObfuscationCamelToSnake], onlyFilename: Bool) {
        self.configs = configs
        self.onlyFilename = onlyFilename
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
        try files.forEach {
            try $0.newPath(resolvePath($0.filePath))
        }
        return files
    }

    open func resolvePath(_ path: Path) throws -> Path {
        let rules: [Rule] = configs.map {
            Rule(
                enabled: true,
                appliesTo: [.path],
                scope: .init(onlyPrefix: false, onlyFilename: onlyFilename),
                kind: .caseConvert(prefix: $0.prefix, toLowercase: $0.toLowercase ?? true, direction: .snakeToCamel)
            )
        }
        return transformer.transform(path, rules: rules)
    }

    func snameToCamel(_ name: String, config: ObfuscationCamelToSnake) -> String {
        name.components(separatedBy: .newlines)
            .map {
                guard $0.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(config.prefix) else {
                    return $0
                }

                let string = $0.replacingOccurrences(of: config.prefix, with: "PREFIX_")
//                let line = string.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1_$2", options: .regularExpression)
                let line = string.components(separatedBy: "_")
                    .map {
                        if $0 != "PREFIX" {
                            print($0.capitalized)
                            return $0.capitalized
                        }
                        return $0
                    }
                    .joined()
                return line
                    .replacingOccurrences(of: "PREFIX", with: config.prefix)
            }
            .joined(separator: "\n")
    }

    func resolvePathComponent(_ pathComponent: String) -> String {
        configs.reduce(pathComponent) {
            snameToCamel(
                $0,
                config: $1
            )
        }
    }
}
