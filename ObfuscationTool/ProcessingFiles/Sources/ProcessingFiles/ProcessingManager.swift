//
//  File.swift
//
//
//  Created by mayong on 2023/8/28.
//

import CodeProtocol
import FilePath
import Foundation

public protocol ProcessingFilePlugin {
    func processingManager(_ manager: ProcessingManager, processedFile file: FilePathProtocol) throws -> [CodeRawProtocol]
    
    func processingManager(_ manager: ProcessingManager, processedDirectoryOrFile path: PathProtocol) throws -> ProcessingFile

    func processingManager(_ manager: ProcessingManager, completedProcessFile files: [ProcessingFile]) throws -> [ProcessingFile]
}

public extension ProcessingFilePlugin {
    func processingManager(_ manager: ProcessingManager, processedDirectoryOrFile path: PathProtocol) throws -> ProcessingFile {
        ProcessingFile(filePath: path, fileType: .init(ext: path.pathExtension))
    }

    func processingManager(_ manager: ProcessingManager, processedFile file: FilePathProtocol) throws -> [CodeRawProtocol] {
        []
    }

    func processingManager(_ manager: ProcessingManager, completedProcessFile files: [ProcessingFile]) throws -> [ProcessingFile] {
        []
    }
}

public protocol ProcessingManagerDelegate: AnyObject {
    func processingManager(_ manager: ProcessingManager, willProcessing file: PathProtocol)
}

public final class ProcessingManager {
    
    public weak var delegate: ProcessingManagerDelegate?
        
    public let path: PathProtocol
    public init(path: PathProtocol) {
        self.path = path
    }
    
    public private(set) var pluginCache: [FileType: ProcessingFilePlugin] = [:]
    
    public func registerPlugin(_ plugin: ProcessingFilePlugin, forFileType fileType: FileType) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        pluginCache[fileType] = plugin
    }
    
    public func processingString() throws -> String {
        try processing()
            .map { try $0.getContent() }
            .joined()
    }
    
    public func processing() throws -> [ProcessingFile] {
        guard path.isExists else { return [] }
        var retFiles: [FileType: [ProcessingFile]] = [:]
        if path.isFile {
            if let processedFile = processingFile(path as! FilePath) {
                retFiles = [processedFile.fileType: [processedFile]]
            }
        } else {
            retFiles = try processingDirectory(path as! DirectoryPath)
        }
        return try retFiles
            .map {
                if let plugin = self.pluginCache[$0.key] {
                    return try plugin.processingManager(self, completedProcessFile: $0.value)
                }
                return $0.value
            }
            .flatMap { $0 }
    }
}

// MARK: - Private

extension ProcessingManager {
    private func processingFile(_ filePath: FilePath) -> ProcessingFile? {
        delegate?.processingManager(self, willProcessing: filePath)
        let fileType = FileType(ext: filePath.pathExtension)
        do {
            if let handlePlugin = pluginCache[fileType] {
                switch fileType {
                case .swift, .header, .implemention:
                    let codes = try handlePlugin.processingManager(self, processedFile: filePath)
                    let file = ProcessingFile(filePath: filePath, fileType: fileType)
                    file.setCodes(codes)
                    return file
                default:
                    let file = try handlePlugin.processingManager(self, processedDirectoryOrFile: filePath)
                    return file
                }
            }
            return nil
        } catch {
            return nil
        }
    }
    
    private func processingDirectory(_ direcotryPath: DirectoryPath) throws -> [FileType: [ProcessingFile]] {
        var processedFiles: [FileType: [ProcessingFile]] = [:]
        delegate?.processingManager(self, willProcessing: direcotryPath)
        if direcotryPath.isBundle || direcotryPath.isAssets || direcotryPath.pathExtension == "lproj",
           let plugin = pluginCache[.init(ext: direcotryPath.pathExtension)]
        {
            let file = try plugin.processingManager(self, processedDirectoryOrFile: direcotryPath)
            let fileType = FileType(ext: path.pathExtension)
            processedFiles[fileType] = [file]
        } else {
            for path in direcotryPath.directoryIterator() {
                if path.isFile {
                    if let processedFile = processingFile(path as! FilePath) {
                        let type = processedFile.fileType
                        var files = processedFiles[type] ?? []
                        files.append(processedFile)
                        processedFiles[type] = files
                    }
                } else {
                    processedFiles.merge(try processingDirectory(path as! DirectoryPath), uniquingKeysWith: { $0 + $1 })
                }
            }
        }
        return processedFiles
    }
}
