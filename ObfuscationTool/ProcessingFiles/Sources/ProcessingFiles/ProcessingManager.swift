//
//  File.swift
//  
//
//  Created by mayong on 2023/8/28.
//

import Foundation
import FilePath
import CodeProtocol

public protocol ProcessingFilePlugin {
    func processingManager(_ manager: ProcessingManager, processedFile file: FilePathProtocol) throws -> [CodeRawProtocol]
}

public final class ProcessingManager {
        
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
            .map({ try $0.getContent() })
            .joined()
    }
    
    public func processing() -> [ProcessingFile] {
        guard path.isExists else { return [] }
        if path.isFile {
            if let processedFile = processingFile(path as! FilePath) {
                return [processedFile]
            }
            return []
        } else {
            return processingDirectory(path as! DirectoryPath)
        }
    }
}

// MARK: - Private
extension ProcessingManager {
    
    private func processingFile(_ filePath: FilePath) -> ProcessingFile? {
        
        let fileType = FileType(ext: filePath.pathExtension)
        do {
            if let handlePlugin = pluginCache[fileType] {
                let codes = try handlePlugin.processingManager(self, processedFile: filePath)
                let file = ProcessingFile(filePath: filePath, fileType: fileType)
                file.setCodes(codes)
                return file
            }
            return nil
        } catch {
            return nil
        }
    }
    
    private func processingDirectory(_ direcotryPath: DirectoryPath) -> [ProcessingFile] {
        
        var processedFiles: [ProcessingFile] = []
        for path in direcotryPath.directoryIterator() {
            if path.isFile {
                if let processedFile = processingFile(path as! FilePath) {
                    processedFiles.append(processedFile)
                }
            } else {
                processedFiles.append(contentsOf: processingDirectory(path as! DirectoryPath))
            }
        }
        return processedFiles
    }
}
