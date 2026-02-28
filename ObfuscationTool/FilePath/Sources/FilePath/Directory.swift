//
//  File.swift
//
//
//  Created by mayong on 2023/8/25.
//

import Foundation

public protocol DirectoryPathProtocol: PathProtocol {
    var parent: DirectoryPathProtocol { get }
    
    var subpaths: [String] { get }
    
    var isEmpty: Bool { get }
    
    var isBundle: Bool { get }
    
    var isZip: Bool { get }
    
    var isAssets: Bool { get }
        
    func appendConponent(_ name: String) -> DirectoryPathProtocol
    
    func directoryIterator() -> DirectoryIterator
    
    func forEach(_ closure: (PathProtocol) throws -> Void) rethrows
}

public extension DirectoryPathProtocol {
    var subpaths: [String] {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: path)
        } catch {
            print(error)
            return []
        }
    }
    
    var isEmpty: Bool {
        subpaths.isEmpty
    }
    
    func createIfNotExists() throws {
        guard !isExists else { return }
        try parent.createIfNotExists()
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }
    
    func rename(_ newName: String) throws -> PathProtocol {
        let newPath: DirectoryPathProtocol = parent.appendConponent(newName)
        try FileManager.default.moveItem(atPath: path, toPath: newPath.path)
        return newPath
    }
    
    func remove() throws {
        var fileStack: [String] = [path]
        while !fileStack.isEmpty {
            let file = fileStack.last!
            
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: file, isDirectory: &isDirectory) else {
                fileStack.removeLast()
                continue
            }
            
            if !isDirectory.boolValue {
                try FileManager.default.removeItem(atPath: file)
                fileStack.removeLast()
            } else {
                let subpaths = FileManager.default.subpaths(atPath: file) ?? []
                if subpaths.isEmpty {
                    try FileManager.default.removeItem(atPath: file)
                    fileStack.removeLast()
                } else {
                    for subpath in subpaths {
                        let fullPath = String(format: "%@/%@", file, subpath)
                        fileStack.append(fullPath)
                    }
                }
            }
        }
    }
    
    var isBundle: Bool {
        pathExtension == "bundle"
    }
    
    var isZip: Bool {
        pathExtension == "zip"
    }

    var isAssets: Bool {
        pathExtension == "xcassets"
    }
    
    func directoryIterator() -> DirectoryIterator {
        DirectoryIterator(directory: self)
    }
    
    func forEach(_ closure: (PathProtocol) throws -> Void) rethrows {
        try directoryIterator().forEach(closure)
    }
}

public struct DirectoryPath {
    public let path: String
    
    public init(path: String) {
        self.path = path
    }
    
    public static let document = DirectoryPath(path: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
    public static let library = DirectoryPath(path: NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0])
    public static let cache = DirectoryPath(path: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])
    
    public static let infoPlist = DirectoryPath(path: Bundle.main.path(forResource: "Info", ofType: "plist")!)

    public static let temp = DirectoryPath(path: NSTemporaryDirectory())
    
    public static let mainBundle = DirectoryPath(path: Bundle.main.bundlePath)

    @available(macOS 10.13, *)
    public static let desktop = DirectoryPath(path: String(format: "%@/Desktop", pwd))
    @available(macOS 10.13, *)
    public static let download = DirectoryPath(path: String(format: "%@/Downloads", pwd))
    @available(macOS 10.13, *)
    public static let home = DirectoryPath(path: pwd)
    
    public static let current = DirectoryPath(path: FileManager.default.currentDirectoryPath)
    
    public static func changeToCurrent(_ newCurrent: DirectoryPath) {
        FileManager.default.changeCurrentDirectoryPath(newCurrent.path)
    }
    
    @available(macOS 10.13, *)
    private static let homePath: String = {
        let homeDirectory = NSHomeDirectory()
        let homeComponents = homeDirectory.components(separatedBy: "/")
        return Array(homeComponents[0 ..< 3]).joined(separator: "/")
    }()
    
    @available(macOS 10.13, *)
    private static let pwd: String = {
        if let pw = getpwuid(getuid()), var pw_dir = pw.pointee.pw_dir {
            return String(cString: pw_dir)
        }
        return homePath
    }()
}

extension DirectoryPath: DirectoryPathProtocol {
    public func appendConponent(_ name: String) -> DirectoryPathProtocol {
        let fullPath = String(format: "%@/%@", path, name)
        return DirectoryPath(path: fullPath)
    }
    
    public var parent: DirectoryPathProtocol {
        if let index = path.lastIndex(of: "/") {
            let range = path.startIndex ..< index
            return DirectoryPath(path: String(path[range]))
        }
        return self
    }
}
