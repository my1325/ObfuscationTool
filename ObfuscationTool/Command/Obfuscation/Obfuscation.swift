//
//  Obfuscation.swift
//  Command
//
//  Created by mayong on 2023/9/27.
//

import Foundation
import PathKit
import Plugins
import ProcessingFiles
import SwiftFilePlugin

internal final class Obfuscation {
    let config: ObfuscationConfig
    init(config: ObfuscationConfig) {
        self.config = config
    }
        
    var input: Path {
        Path.current + (config.input ?? "")
    }
    
    var output: Path {
        if let output = config.output, !output.isEmpty {
            return Path.current + output
        }
        return input
    }
    
    var keepDirectory: Bool {
        config.keepDirectory ?? false
    }
        
    func run() throws {
        let input = input
        
        if !input.exists {
            throw ObfuscationError.inputNotExists(input.string)
        }
        
        try run(input)
    }
    
    private func checkOutput() throws -> Path {
        let outputPath = output
        guard outputPath.isDirectory else {
            throw ObfuscationError.outputIsNotValid(outputPath.string)
        }
           
        try outputPath.mkpath()
        return outputPath
    }
    
    private func shuffulePlugin(_ config: ObfuscationShuffule) -> SwiftFileProcessingHandlePluginProtocol {
        FileShuffleHandlePlugin(order: config.order ?? false)
    }
    
    private func replacePlugin(_ config: ObfuscationReplace) -> SwiftFileProcessingHandlePluginProtocol {
        let modes: [FileStringHandlePlugin.HandleMode] = config.map?
            .map {
                .replace(
                    prefixOnly: config.onlyPrefix ?? false,
                    originString: $0.key,
                    replaceString: $0.value
                )
            } ?? []
        return FileStringHandlePlugin(modes)
    }
    
    private func swiftFilePlugins() -> SwiftFileProcessingPlugin {
        var plugins: [SwiftFileProcessingHandlePluginProtocol] = []
        
        if let replaceConfig = config.replace {
            plugins.append(replacePlugin(replaceConfig))
        }
        
        if let shuffle = config.shuffule {
            plugins.append(shuffulePlugin(shuffle))
        }
        
        return SwiftFileProcessingPlugin(plugins: plugins)
    }
        
    private func run(_ filePath: Path) throws {
        
        let processingManager = ProcessingManager(path: filePath)
        processingManager.registerPlugin(swiftFilePlugins(), forFileType: .swift)
        if let replace = config.replace {
            processingManager.registerPlugin(NameReplacePlugin(replace), forFileType: .all)
        }
        processingManager.delegate = self
        
        let files = try processingManager.processing()
        
        for file in files {
            guard !file.filePath.lastComponent.starts(with: ".") else {
                continue
            }
            try saveFile(file, in: getOutputPath(file))
        }
    }
    
    private func getOutputPath(_ file: ProcessingFile) throws -> Path {
        guard keepDirectory else { return output }
        let originPath = file.filePath.string
        let index = originPath.index(originPath.startIndex, offsetBy: input.string.count)
        let fileRelativePath = originPath.suffix(from: index)
        return Path(output.string + String(fileRelativePath))
            .parent()
    }
    
    private func saveFile(_ file: ProcessingFile, in path: Path) throws {
        let newPath = path + file.output.lastComponent
        try newPath.parent().mkpath()
        
        if file.filePath != newPath, newPath.exists {
            try newPath.delete()
        }
        
        if file.fileType.isCode {
            try newPath.write(file.getContent())
        } else {
            try newPath.write(file.getData())
        }
        
        if file.filePath != newPath, file.filePath.exists {
            try file.filePath.delete()
        }
    }
}

extension Obfuscation: ProcessingManagerDelegate {
    func processingManager(_ manager: ProcessingManager, willProcessing file: Path) {}
    
    private func isHandledFile(_ fileType: FileType) -> Bool {
        switch fileType {
        case .header, .implemention: return false
        default: return true
        }
    }
}
