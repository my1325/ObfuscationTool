//
//  File.swift
//
//
//  Created by mayong on 2023/8/25.
//

import Foundation

public protocol FilePathProtocol: PathProtocol {
    var parent: DirectoryPathProtocol { get }
        
    func writeData(_ data: Data) throws
    
    func readData() throws -> Data
    
    func fileIterator() throws -> FileIterator
    
    func readLine(_ block: @escaping (String) -> Void) throws
    
    func readLines() throws -> [String]
}

public extension FilePathProtocol {
    
    var parent: DirectoryPathProtocol {
        if let index = path.lastIndex(of: "/") {
            let range = path.startIndex ..< index
            return DirectoryPath(path: String(path[range]))
        }
        return DirectoryPath(path: path)
    }
    
    func createIfNotExists() throws {
        guard !isExists else { return }
        try parent.createIfNotExists()
        FileManager.default.createFile(atPath: path, contents: nil)
    }
    
    func rename(_ newName: String) throws -> PathProtocol {
        let newPath: FilePathProtocol = parent.appendFileName(newName)
        try FileManager.default.moveItem(atPath: path, toPath: newPath.path)
        return newPath
    }
    
    func remove() throws {
        try FileManager.default.removeItem(atPath: path)
    }
    
    func writeData(_ data: Data) throws {
        try createIfNotExists()
        try data.write(to: URL(fileURLWithPath: path))
    }
    
    func readData() throws -> Data {
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }
    
    func fileIterator() throws -> FileIterator {
        return try FileIterator(url: URL(fileURLWithPath: path))
    }
    
    func readLine(_ block: @escaping (String) -> Void) throws {
        for line in try fileIterator() {
            block(line)
        }
    }
    
    func readLines() throws -> [String] {
        var lines: [String] = []
        for line in try fileIterator() {
            lines.append(line)
        }
        return lines
    }
    
    var isReadable: Bool {
        FileManager.default.isReadableFile(atPath: path)
    }

    var isWritable: Bool {
        FileManager.default.isWritableFile(atPath: path)
    }
    
    var isExecutable: Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }

    var isDeletable: Bool {
        FileManager.default.isDeletableFile(atPath: path)
    }
}

public struct FilePath: FilePathProtocol {
    public let path: String
    public init(path: String) {
        self.path = path
    }
}

public extension DirectoryPathProtocol {
    func appendFileName(_ name: String, ext: String = "") -> FilePathProtocol {
        if !ext.isEmpty {
            return FilePath(path: String(format: "%@/%@.%@", path, name, ext))
        } else {
            return FilePath(path: String(format: "%@/%@", path, name))
        }
    }
}
