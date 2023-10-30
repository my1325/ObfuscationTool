//
//  Obfuscation.swift
//  Command
//
//  Created by mayong on 2023/9/27.
//

import FilePath
import Foundation
import Plugins
import ProcessingFiles
import SwiftFilePlugin

internal final class Obfuscation {
    let config: ObfuscationConfig
    init(config: ObfuscationConfig) {
        self.config = config
    }
    
    var git: ObfuscationGit? { config.git }
    
    var input: String? { config.path }
    
    var output: String? { config.output }
        
    func run() throws {
        let outputDirection = try checkOutput()
       
        if let input {
            let inputPath: PathProtocol
            if input.starts(with: "/") {
                inputPath = DirectoryPath(path: input)
            } else {
                inputPath = currentWorkSpace.appendConponent(input)
            }
            try checkPath(inputPath, output: outputDirection)
        }
    }
    
    private func checkGit() {}
    
    private func checkPath(_ filePath: PathProtocol, output: DirectoryPathProtocol) throws {
        let replaceConfig = config.replace ?? .default
        let prefixConfig = config.prefix ?? .default
        let zips = config.zips ?? []
        
        var plugins: [SwiftFileProcessingHandlePluginProtocol] = []
        
        if let map = replaceConfig.map {
            typealias HandleMode = FileStringHandlePlugin.HandleMode
            let handleMode: [HandleMode] = map.map { .replace(originString: $0.key, replaceString: $0.value) }
            let prefixPlugin = FileStringHandlePlugin(handleMode)
            plugins.append(prefixPlugin)
        }
        
        if let prefixString = prefixConfig.prefix {
            typealias HandleMode = FileStringHandlePlugin.HandleMode
            let shouldAdd = prefixConfig.shouldAdd ?? false
            let separator = prefixConfig.separator?.first ?? "-"
            let prefixMode: HandleMode.PrefixMode = shouldAdd ? .addOrReplace : .replace
            let handleMode: [HandleMode] = [.prefix(mode: prefixMode, prefix: prefixString, separator: separator)]
            let prefixPlugin = FileStringHandlePlugin(handleMode, codeType: [.property, .func], codeContainerType: [.none])
            plugins.append(prefixPlugin)
        }
        
        if let shuffle = config.shuffule {
            let shufflePlugin = FileShuffleHandlePlugin(order: shuffle.order ?? false)
            plugins.append(shufflePlugin)
        }
        
        let resourcePlugin = ResourceProcessingPlugin(destination: try getAssetsDirectory(output),
                                                      replaceConfig: replaceConfig,
                                                      prefixConfig: prefixConfig,
                                                      zips: zips)
        
        let processingManager = ProcessingManager(path: filePath)
        processingManager.registerPlugin(SwiftFileProcessingPlugin(plugins: plugins), forFileType: .swift)
        processingManager.registerPlugin(resourcePlugin, forFileType: .image)
        processingManager.registerPlugin(resourcePlugin, forFileType: .bundle)
        processingManager.registerPlugin(resourcePlugin, forFileType: .assets)
        processingManager.registerPlugin(resourcePlugin, forFileType: .zip)
        processingManager.registerPlugin(resourcePlugin, forFileType: .lproj)
        processingManager.registerPlugin(resourcePlugin, forFileType: .font)
        processingManager.registerPlugin(resourcePlugin, forFileType: .svga)
        processingManager.registerPlugin(resourcePlugin, forFileType: .other)
        processingManager.delegate = self
        let files = try processingManager.processing()
        try completedProcessing(files, output: output)
    }
    
    private func completedProcessing(_ files: [ProcessingFile], output: DirectoryPathProtocol) throws {
        let codeDirectory = try getCodeDirectory(output)
        for file in files {
            if file.fileType.isCode {
                try saveFileAtOutput(file, output: codeDirectory)
            }
        }
    }
    
    private func saveFileAtOutput(_ file: ProcessingFile, output: DirectoryPathProtocol) throws {
        let codeString = try file.getContent()
        if let codeData = codeString.data(using: .utf8) {
            let filename = getFilename(file.filePath.lastPathConponent)
            let newFilePath = output.appendFileName(filename)
            try newFilePath.writeData(codeData)
        } else {
            throw ObfuscationError.codeCannotWrite(codeString)
        }
    }
    
    private func checkOutput() throws -> DirectoryPathProtocol {
        guard let output, !output.isEmpty else { throw ObfuscationError.outputEmpty }
        var outputPath: DirectoryPathProtocol = currentWorkSpace
        if output.starts(with: "/") {
            outputPath = DirectoryPath(path: output)
        } else {
            outputPath = currentWorkSpace.appendConponent(output)
        }
        
        if outputPath.isFile {
            throw ObfuscationError.outputIsFile(outputPath.path)
        }
        
        try outputPath.createIfNotExists()
        return outputPath
    }
    
    private func getCodeDirectory(_ parent: DirectoryPathProtocol) throws -> DirectoryPathProtocol {
        let codeDirectory = parent.appendConponent("code")
        try codeDirectory.createIfNotExists()
        return codeDirectory
    }
    
    private func getAssetsDirectory(_ parent: DirectoryPathProtocol) throws -> DirectoryPathProtocol {
        let assetDirectory = parent.appendConponent("assets")
        try assetDirectory.createIfNotExists()
        return assetDirectory
    }
    
    private func getFilename(_ origin: String) -> String {
        var retName = origin
        if retName.hasPrefix("/") {
            retName.removeFirst()
        }
        
        var handleFile = config.replace?.handleFile ?? true
        if handleFile, let replace = config.replace { retName = replace.getName(retName) }
        
        handleFile = config.prefix?.handleFile ?? true
        if handleFile, let prefix = config.prefix { retName = prefix.getName(retName) }
        return retName
    }
}

extension Obfuscation: ProcessingManagerDelegate {
    func processingManager(_ manager: ProcessingManager, willProcessing file: PathProtocol) {
        let fileType = FileType(ext: file.pathExtension)
        guard !isHandledFile(fileType) else { return }
        
        do {
            let output = try checkOutput()
            let fileName = getFilename(file.lastPathConponent)
            let newPath: FilePathProtocol
            if fileType.isCode {
                newPath = try getCodeDirectory(output).appendFileName(fileName)
            } else {
                newPath = try getAssetsDirectory(output).appendFileName(fileName)
            }
            try file.copyToPath(newPath)
        } catch {
            print(error)
        }
    }
    
    private func isHandledFile(_ fileType: FileType) -> Bool {
        switch fileType {
        case .header, .implemention: return false
        default: return true
        }
    }
}
