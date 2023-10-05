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
        if let input, let path = Path.instanceOfPath(input) {
            try checkPath(path, output: outputDirection)
        }
    }
    
    private func checkGit() {}
    
    private func checkPath(_ filePath: PathProtocol, output: DirectoryPathProtocol) throws {
        var plugins: [SwiftFileProcessingHandlePluginProtocol] = []
        
        if let replace = config.replace {
            typealias HandleMode = FileStringHandlePlugin.HandleMode
            let handleMode: [HandleMode] = replace.map?.map { .replace(originString: $0.key, replaceString: $0.value) } ?? []
            let prefixPlugin = FileStringHandlePlugin(handleMode)
            plugins.append(prefixPlugin)
        }
        
        if let prefix = config.prefix, let prefixString = prefix.prefix {
            typealias HandleMode = FileStringHandlePlugin.HandleMode
            let shouldAdd = prefix.shouldAdd ?? false
            let separator = prefix.separator?.first ?? "-"
            let prefixMode: HandleMode.PrefixMode = shouldAdd ? .addOrReplace : .replace
            let handleMode: [HandleMode] = [.prefix(mode: prefixMode, prefix: prefixString, separator: separator)]
            let prefixPlugin = FileStringHandlePlugin(handleMode)
            plugins.append(prefixPlugin)
        }
        
        if let shuffle = config.shuffule {
            let shufflePlugin = FileShuffleHandlePlugin(order: shuffle.order ?? false)
            plugins.append(shufflePlugin)
        }
        
        let processingManager = ProcessingManager(path: filePath)
        processingManager.registerPlugin(SwiftFileProcessingPlugin(plugins: plugins), forFileType: .swift)
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
            try newFilePath.createIfNotExists()
            try newFilePath.writeData(codeData)
        }
        throw ObfuscationError.codeCannotWrite(codeString)
    }
    
    private func checkOutput() throws -> DirectoryPathProtocol {
        guard let output, !output.isEmpty else { throw ObfuscationError.outputEmpty }
        var outputPath: DirectoryPathProtocol = DirectoryPath.current
        if output.starts(with: "/") {
            outputPath = DirectoryPath(path: output)
        } else {
            outputPath = DirectoryPath.current.appendConponent(output)
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
        var handleFile = config.replace?.handleFile ?? true
        var retName: String = origin
        if handleFile, let map = config.replace?.map {
            retName = map.reduce(origin) { $0.replacingOccurrences(of: $1.key, with: $1.value) }
        }
        
        handleFile = config.prefix?.handleFile ?? true
        let separator = config.prefix?.separator?.first ?? "-"
        let shouldAdd = config.prefix?.shouldAdd ?? false
        if handleFile, let prefix = config.prefix?.prefix {
            let prefixString = String(format: "%@%@", prefix, String(separator))
            if retName.hasPrefix(prefixString) {
                let startIndex = retName.index(retName.startIndex, offsetBy: prefixString.count)
                retName = String(format: "%@%@", prefixString, String(retName[startIndex ..< retName.endIndex]))
            } else if shouldAdd {
                retName = String(format: "%@%@", prefixString, retName)
            }
        }
        return retName
    }
}

extension Obfuscation: ProcessingManagerDelegate {
    func processingManager(_ manager: ProcessingManager, willProcessing file: FilePathProtocol) {
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
            try FileManager.default.copyItem(atPath: file.path, toPath: newPath.path)
        } catch {
            print(error)
        }
    }
    
    private func isHandledFile(_ fileType: FileType) -> Bool {
        switch fileType {
        case .swift: return true
        default: return false
        }
    }
}
