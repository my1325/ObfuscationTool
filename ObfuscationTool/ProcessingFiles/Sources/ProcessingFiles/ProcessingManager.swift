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
    func processingManager(_ manager: ProcessingManager, processedFile file: FilePath) throws -> ProcessingFile
}

public protocol ProcessingManagerDelegate: AnyObject {
    func processingManager(_ manager: ProcessingManager, willProcessingFile at: Path)
        
    func processingManager(_ manager: ProcessingManager, didProcessingFile at: Path)
    
    func processingManager(_ manager: ProcessingManager, didProcessingWithError error: ProcessingError)
    
    func processingManager(_ manager: ProcessingManager, didProcessedFile file: ProcessingFile)
}

public extension ProcessingManagerDelegate {
    func processingManager(_ manager: ProcessingManager, willProcessingFile at: Path) {
        debugPrint("processing manager will processing \(at)")
    }
        
    func processingManager(_ manager: ProcessingManager, didProcessingFile at: Path) {
        debugPrint("processing manager did processing \(at)")
    }
    
    func processingManager(_ manager: ProcessingManager, didProcessingWithError error: ProcessingError) {
        debugPrint(error)
    }
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
    
    public func startParse() -> String {
        let files = processing()
        let filesString = files.reduce("", {  $0.appending($1.content) })
        return filesString
    }
}

// MARK: - Private
extension ProcessingManager {
    private func processing() -> [ProcessingFile] {
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
    
    private func processingFile(_ filePath: FilePath) -> ProcessingFile? {
        
        delegate?.processingManager(self, willProcessingFile: filePath)
        defer { delegate?.processingManager(self, didProcessingFile: filePath) }
        
        let fileType = FileType(ext: filePath.pathExtension)
        do {
            if let handlePlugin = pluginCache[fileType] {
                return try handlePlugin.processingManager(self, processedFile: filePath)
            }
            processingErrorOccurred(.notPluginForFileType(fileType))
            return nil
        } catch {
            processingErrorOccurred(.underlying(error))
            return nil
        }
    }
    
    private func processingDirectory(_ direcotryPath: DirectoryPath) -> [ProcessingFile] {
        
        delegate?.processingManager(self, willProcessingFile: direcotryPath)
        defer { delegate?.processingManager(self, didProcessingFile: direcotryPath) }
        
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
    
    private func processingErrorOccurred(_ error: ProcessingError) {
        delegate?.processingManager(self, didProcessingWithError: error)
    }
}
