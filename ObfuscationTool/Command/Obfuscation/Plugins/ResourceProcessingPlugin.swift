//
//  File.swift
//
//
//  Created by my on 2023/10/5.
//

import FilePath
import Foundation
import ProcessingFiles
import ZipArchive

public final class ResourceProcessingPlugin: ProcessingFilePlugin {
    let destination: DirectoryPathProtocol
    let replaceConfig: ObfuscationReplace
    let prefixConfig: ObfuscationPrefix
    let zips: [ObfuscationZip]
    init(destination: DirectoryPathProtocol, replaceConfig: ObfuscationReplace, prefixConfig: ObfuscationPrefix, zips: [ObfuscationZip]) {
        self.destination = destination
        self.prefixConfig = prefixConfig
        self.replaceConfig = replaceConfig
        self.zips = zips
    }
    
    public func processingManager(_ manager: ProcessingManager, processedDirectoryOrFile path: PathProtocol) throws -> ProcessingFile {
        let fileType = FileType(ext: path.pathExtension)
        switch fileType {
        case .bundle: handleBundleAtPath(path)
        case .assets: handleAssetsAtPath(path)
        case .zip: handleZipAtPath(path)
        case .lproj: handleLprojAtPath(path)
        default: break
        }
        return ProcessingFile(filePath: path, fileType: fileType)
    }
    
    private func handleBundleAtPath(_ path: PathProtocol) {
        let bundleTools = ResourcePluginTools(destination: destination, replaceConfig: replaceConfig, prefixConfig: prefixConfig, zips: zips)
        do {
            try bundleTools.runWithPath(path, copyToDestination: true)
        } catch {
            print(error)
        }
    }
    
    private func handleAssetsAtPath(_ path: PathProtocol) {
        let bundleTools = AssetsResourcePluginTools(destination: destination, replaceConfig: replaceConfig, prefixConfig: prefixConfig, zips: zips)
        do {
            try bundleTools.runWithPath(path, copyToDestination: true)
        } catch {
            print(error)
        }
    }
    
    private func handleZipAtPath(_ path: PathProtocol) {
        let bundleTools = ZipResourcePluginTools(destination: destination, replaceConfig: replaceConfig, prefixConfig: prefixConfig, zips: zips)
        do {
            try bundleTools.runWithPath(path, copyToDestination: true)
        } catch {
            print(error)
        }
    }
    
    private func handleLprojAtPath(_ path: PathProtocol) {
        let bundleTools = LprojResourcePluginTools(destination: destination, replaceConfig: replaceConfig, prefixConfig: prefixConfig, zips: zips)
        do {
            try bundleTools.runWithPath(path, copyToDestination: true)
        } catch {
            print(error)
        }
    }
}

internal class ResourcePluginTools {
    let destination: DirectoryPathProtocol
    let replaceConfig: ObfuscationReplace
    let prefixConfig: ObfuscationPrefix
    let zips: [ObfuscationZip]
    init(destination: DirectoryPathProtocol,
         replaceConfig: ObfuscationReplace,
         prefixConfig: ObfuscationPrefix,
         zips: [ObfuscationZip])
    {
        self.zips = zips
        self.destination = destination
        self.replaceConfig = replaceConfig
        self.prefixConfig = prefixConfig
    }
    
    func runWithPath(_ path: PathProtocol, copyToDestination: Bool) throws {
        let outputPath = destination.appendConponent(getName(path))

        if copyToDestination {
            try path.copyToPath(outputPath)
        }
        
        try runWithParent(destination, path: path, copyToDestination: copyToDestination)
    }
    
    func runWithParent(_ parent: DirectoryPathProtocol, path: PathProtocol, copyToDestination: Bool) throws {
        let outputPath = parent.appendConponent(getName(path))

        if copyToDestination {
            try path.copyToPath(outputPath)
        }
        
        for subpath in outputPath.directoryIterator() {
            let newName = getName(subpath)
            let newPath = try subpath.rename(newName)
            if let directory = newPath as? DirectoryPathProtocol {
                if directory.isBundle {
                    let tools = ResourcePluginTools(destination: outputPath, replaceConfig: replaceConfig, prefixConfig: prefixConfig, zips: zips)
                    try tools.runWithPath(directory, copyToDestination: false)
                } else if directory.isAssets {
                    let tools = AssetsResourcePluginTools(destination: outputPath, replaceConfig: replaceConfig, prefixConfig: prefixConfig, zips: zips)
                    try tools.runWithPath(directory, copyToDestination: false)
                } else if directory.isZip {
                    let tools = ZipResourcePluginTools(destination: outputPath, replaceConfig: replaceConfig, prefixConfig: prefixConfig, zips: zips)
                    try tools.runWithPath(directory, copyToDestination: false)
                } else {
                    try runWithParent(outputPath, path: directory, copyToDestination: false)
                }
            } else if let filePath = newPath as? FilePathProtocol {
                
            }
        }
    }
    
    func getName(_ path: PathProtocol) -> String {
        let origin = path.lastPathConponent
        var handleFile = replaceConfig.handleFile ?? true
        var retName: String = origin
        
        if handleFile { retName = replaceConfig.getName(origin) }
        
        handleFile = prefixConfig.handleFile ?? true
        if handleFile { retName = prefixConfig.getName(retName) }
        
        if retName.hasPrefix("/") {
            retName.removeFirst()
        }
        return retName
    }
}

internal final class AssetsResourcePluginTools: ResourcePluginTools {
    
    override func runWithPath(_ path: PathProtocol, copyToDestination: Bool) throws {
        let outputPath = destination.appendConponent(getName(path))

        if copyToDestination {
            try path.copyToPath(outputPath)
        }
        
        try runWithAssets(outputPath)
    }
    
    private func runWithAssets(_ assetsDirectory: DirectoryPathProtocol) throws {
        for subpath in assetsDirectory.directoryIterator() {
            if subpath.pathExtension == "imageset" {
                let newName = getName(subpath)
                let newAssetsDirectory = try subpath.rename(newName)
                try handleImageAsset(newAssetsDirectory as! DirectoryPathProtocol)
            } else if subpath.pathExtension == "colorset" || subpath.pathExtension == "appiconset" {
                continue
            } else if let directoryPath = subpath as? DirectoryPathProtocol {
                let newName = getName(directoryPath)
                let newAssetsDirectory = try directoryPath.rename(newName)
                try runWithAssets(newAssetsDirectory as! DirectoryPathProtocol)
            }
        }
    }
    
    private func handleImageAsset(_ path: DirectoryPathProtocol) throws {
        let contents = path.appendFileName("Contents.json")
        guard contents.isExists else { return }
        var name = path.lastPathConponent
        if let lastIndex = name.lastIndex(of: ".") {
            name = String(name[name.startIndex ..< lastIndex])
        }
        
        let jsonData = try contents.readData()
        if var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any],
           var images = jsonDict["images"] as? [[String: Any]]
        {
            for index in 0 ..< images.count {
                var imageDict = images[index]
                imageDict["filename"] = name
                images[index] = imageDict
            }
            jsonDict["images"] = images
            let data = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            try contents.writeData(data)
        }
        
        for subpath in path.directoryIterator() {
            if subpath.isFile, subpath.pathExtension == "png" || subpath.pathExtension == "jpg" {
                let newName = getName(subpath)
                _ = try subpath.rename(newName)
            }
        }
    }
}

internal final class ZipResourcePluginTools: ResourcePluginTools {
    
    override func runWithPath(_ path: PathProtocol, copyToDestination: Bool) throws {
        let outputPath = destination.appendFileName(getName(path))

        if copyToDestination {
            try path.copyToPath(outputPath)
        }
        
        try unArchiveZip(outputPath)
    }
    
    func unArchiveZip(_ path: PathProtocol) throws {
        let unArchivePath = destination
        try unArchivePath.createIfNotExists()
        var name = getName(path)
        if let lastIndex = name.lastIndex(of: ".") {
            name = String(name[name.startIndex ..< lastIndex])
        }
        let zip = zipPassword(path, named: name)
        _ = SSZipArchive.unzipFile(atPath: path.path,
                                   toDestination: unArchivePath.path,
                                   overwrite: true, password: zip?.password,
                                   progressHandler: nil)
        
        let resourceTools = ResourcePluginTools(destination: unArchivePath,
                                                replaceConfig: replaceConfig,
                                                prefixConfig: prefixConfig,
                                                zips: zips)
        try resourceTools.runWithPath(unArchivePath.appendConponent(name), copyToDestination: false)
        
        try path.remove()
        
        _ = SSZipArchive.createZipFile(atPath: path.path,
                                   withContentsOfDirectory: unArchivePath.appendConponent(name).path,
                                   withPassword: zip?.newPassword ?? zip?.password)
        
        let nothing = unArchivePath.appendConponent("__MACOSX")
        if nothing.isExists {
            try nothing.remove()
        }
        
        try unArchivePath.appendConponent(name).remove()
    }
    
    func zipPassword(_ path: PathProtocol, named: String) -> ObfuscationZip? {
        zips.filter({ $0.name == named || String(format: "%@.zip", named) == $0.name }).first
    }
}

internal final class LprojResourcePluginTools: ResourcePluginTools {
    
    override func runWithPath(_ path: PathProtocol, copyToDestination: Bool) throws {
        let outputPath = destination.appendConponent(path.lastPathConponent)

        if copyToDestination {
            try path.copyToPath(outputPath)
        }
        
//        for subpath in outputPath.directoryIterator() {
//            try runStringsFile(path)
//        }
    }
    
    private func runStringsFile(_ path: FilePathProtocol) throws {
        
    }
}
