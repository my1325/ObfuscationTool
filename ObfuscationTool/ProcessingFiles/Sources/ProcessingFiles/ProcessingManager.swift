//
//  File.swift
//  
//
//  Created by mayong on 2023/8/28.
//

import Foundation
import FilePath

public protocol ProcessingFilePlugin {
    func processingManager(_ manager: ProcessingManager, processedFile file: FilePath) -> ProcessingFile
}

public final class ProcessingManager {
    public enum FileType {
        /// .swift
        case fSwift
        /// .h
        case fHeader
        /// .m
        case fImplemention
        /// other
        case other
        
        init(ext: String) {
            switch ext {
            case "h": self = .fHeader
            case "swift": self = .fSwift
            case "m": self = .fImplemention
            default: self = .other
            }
        }
    }
    
    public let path: Path
    public init(path: Path) {
        self.path = path
    }
    
    public private(set) var pluginCache: [FileType: ProcessingFilePlugin] = [:]
    
    public func registerPlugin(_ plugin: ProcessingFilePlugin, forFileType fileType: FileType) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        pluginCache[fileType] = plugin
    }
    
    public func processing() -> [ProcessedFile] {
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
    
    public func processingFile(_ filePath: FilePath) -> ProcessedFile? {
        let fileType = FileType(ext: filePath.pathExtension)
        if let handlePlugin = pluginCache[fileType] {
            let processingFile = handlePlugin.processingManager(self, processedFile: filePath)
            return ProcessedFile(processingFile: processingFile)
        }
        return nil
    }
    
    public func processingDirectory(_ direcotryPath: DirectoryPath) -> [ProcessedFile] {
        var processedFiles: [ProcessedFile] = []
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
