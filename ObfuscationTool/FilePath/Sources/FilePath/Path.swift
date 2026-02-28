//
//  File.swift
//  
//
//  Created by mayong on 2023/8/18.
//

import Foundation

public protocol PathProtocol {
    var path: String { get }
    
    var isExists: Bool { get }
        
    var lastPathConponent: String { get }
    
    var isFile: Bool { get }
    
    var isDirectory: Bool { get }
    
    var pathExtension: String { get }
    
    func copyToPath(_ newPath: PathProtocol) throws
        
    func moveToNewPath(_ newPath: PathProtocol) throws

    func rename(_ newName: String) throws -> PathProtocol
    
    func createIfNotExists() throws
    
    func remove() throws
}

public extension PathProtocol {
    
    var pathExtension: String {
        if let index = path.lastIndex(of: ".") {
            let startIndex = path.index(index, offsetBy: 1)
            return String(path[startIndex ..< path.endIndex])
        }
        return ""
    }
    
    var isFile: Bool {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            return !isDirectory.boolValue
        }
        return false
    }
    
    var isDirectory: Bool {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            return isDirectory.boolValue
        }
        return false
    }
    
    var isExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    var lastPathConponent: String {
        if let index = path.lastIndex(of: "/") {
            let range = index ..< path.endIndex
            return String(path[range])
        }
        return path
    }
    
    func moveToNewPath(_ newPath: PathProtocol) throws {
        try FileManager.default.moveItem(atPath: self.path, toPath: newPath.path)
    }
    
    func copyToPath(_ newPath: PathProtocol) throws {
        try FileManager.default.copyItem(atPath: path, toPath: newPath.path)
    }
}

public struct Path {
    public static func instanceOfPath(_ path: String) -> PathProtocol? {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return DirectoryPath(path: path)
            } else {
                return FilePath(path: path)
            }
        }
        return nil
    }
}
