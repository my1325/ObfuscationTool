//
//  File.swift
//
//
//  Created by mayong on 2023/8/28.
//

import CodeProtocol
import Foundation
import PathKit

extension Path {
    var isBundle: Bool {
        self.extension == "bundle"
    }
    
    var isZip: Bool {
        self.extension == "zip"
    }

    var isAssets: Bool {
        self.extension == "xcassets"
    }
    
    var fileType: FileType? {
        guard let `extension` else { return nil }
        return .init(ext: `extension`)
    }
}

public protocol ProcessingFilePlugin {
    func processingManager(
        _ manager: ProcessingManager,
        processedFile file: Path
    ) throws -> [CodeRawProtocol]
    
    func processingManager(
        _ manager: ProcessingManager,
        didProcessedFile file: ProcessingFile
    ) throws -> ProcessingFile
    
    func processingManager(
        _ manager: ProcessingManager,
        completedProcessFile files: [ProcessingFile]
    ) throws -> [ProcessingFile]
}

public extension ProcessingFilePlugin {
    func processingManager(
        _ manager: ProcessingManager,
        processedFile file: Path
    ) throws -> [CodeRawProtocol] {
        []
    }

    func processingManager(
        _ manager: ProcessingManager,
        completedProcessFile files: [ProcessingFile]
    ) throws -> [ProcessingFile] {
        []
    }
}

public protocol ProcessingManagerDelegate: AnyObject {
    func processingManager(
        _ manager: ProcessingManager,
        willProcessing file: Path
    )
}

public final class ProcessingManager {
    public weak var delegate: ProcessingManagerDelegate?
        
    public let path: Path
    public init(path: Path) {
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
        guard path.exists else { return [] }
        var retFiles: [FileType: [ProcessingFile]] = [:]
        if path.isFile {
            retFiles = [path.fileType ?? .other: [try processingFile(path)]]
        } else {
            retFiles = try processingDirectory(path)
        }
        
        let files = try retFiles
            .map {
                try pluginsForType($0.key)?
                    .processingManager(self, completedProcessFile: $0.value) ?? $0.value
            }
            .flatMap { $0 }
        
        return try pluginsForType(.all)?
            .processingManager(self, completedProcessFile: files) ?? files
    }
    
    public func pluginsForType(_ fileType: FileType) -> ProcessingFilePlugin? {
        pluginCache[fileType]
    }
}

// MARK: - Private

extension ProcessingManager {
    private func processingFile(_ filePath: Path) throws -> ProcessingFile {
        delegate?.processingManager(self, willProcessing: filePath)
        
        let fileType = filePath.fileType ?? .other
        let file = ProcessingFile(filePath: filePath, fileType: fileType)
        
        let plugin = pluginsForType(fileType)
        
        let codes: [CodeRawProtocol] = try plugin?.processingManager(self, processedFile: filePath) ?? []
        
        file.setCodes(codes)
        
        return try plugin?.processingManager(self, didProcessedFile: file) ?? file
    }
    
    private func processingDirectory(_ direcotryPath: Path) throws -> [FileType: [ProcessingFile]] {
        delegate?.processingManager(self, willProcessing: direcotryPath)
        
        if let fileType = direcotryPath.fileType,
           let plugin = pluginsForType(fileType)
        {
            var file = ProcessingFile(filePath: direcotryPath, fileType: fileType)
            file = try plugin.processingManager(self, didProcessedFile: file)
            
            return [fileType: [file]]
        }
        
        var processedFiles: [FileType: [ProcessingFile]] = [:]
        
        for path in direcotryPath where path.isFile {
            let processedFile = try processingFile(path)
            let type = processedFile.fileType
            var files = processedFiles[type] ?? []
            files.append(processedFile)
            processedFiles[type] = files
        }
        return processedFiles
    }
}
