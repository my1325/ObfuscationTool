//
//  ResourceFilePlugin.swift
//  Command
//
//  Created by mayong on 2024/9/30.
//

import Foundation
import PathKit
import ProcessingFiles

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
        if onlyFilename {
            return path.parent() + resolvePathComponent(path.lastComponent)
        }
        return Path(
            components: path.components
                .map(resolvePathComponent)
        )
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
