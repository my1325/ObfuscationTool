//
//  ZipTools.swift
//  Command
//
//  Created by mayong on 2024/10/8.
//

import Foundation
import ZipArchive
import PathKit

open class ZipTools {
    let zipConfig: ObfuscationZip
    let zipFile: Path
    
    init(_ zipConfig: ObfuscationZip, zipFile: Path) {
        self.zipConfig = zipConfig
        self.zipFile = zipFile
    }
    
    func resolve(_ resolver: @escaping (Path) throws -> Void) throws {
        let zipPassword = zipConfig.password
        
        let unzipPath = zipFile.parent() + zipFile.lastComponentWithoutExtension
        
        try SSZipArchive.unzipFile(
            atPath: zipFile.string,
            toDestination: unzipPath.string,
            overwrite: true,
            password: zipPassword
        )
        
        try resolve(unzipPath, resolver: resolver)
        
        try zipFile.delete()
        
        SSZipArchive.createZipFile(
            atPath: zipFile.string,
            withContentsOfDirectory: unzipPath.string,
            withPassword: zipConfig.newPassword
        )
    }
    
    private func resolve(
        _ path: Path,
        resolver: (Path) throws -> Void
    ) throws {
        for file in path {
            if file.isFile {
                try resolver(file)
            } else if file.isDirectory {
                try resolve(file, resolver: resolver)
            }
        }
    }
}
