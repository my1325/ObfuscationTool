//
//  StringsFileTools.swift
//  Command
//
//  Created by mayong on 2024/10/8.
//

import Foundation
import PathKit

open class StringsFileTool {
    let stringsPath: Path
    
    var strings: [String: String]
    
    var format: PropertyListSerialization.PropertyListFormat
    
    init(_ stringsPath: Path) throws {
        var plistFormat: PropertyListSerialization.PropertyListFormat = .openStep
        self.strings = try PropertyListSerialization.propertyList(
            from: stringsPath.read(),
            options: .mutableContainersAndLeaves, 
            format: &plistFormat
        ) as? [String: String] ?? [:]
        self.format = plistFormat
        self.stringsPath = stringsPath
    }
    
    func mapKey(_ mapper: (String) -> String) {
        var newStringsValue: [String: String] = [:]
        for (key, value) in strings {
            newStringsValue[mapper(key)] = value
        }
        self.strings = newStringsValue
    }
    
    func resolve(_ resolver: (Path) throws -> Path) throws {
        let newPath = try resolver(stringsPath)
        if stringsPath.exists {
            try stringsPath.delete()
        }
        
        let stringsData = try PropertyListSerialization.data(
            fromPropertyList: strings,
            format: format,
            options: .zero
        )
        
        try newPath.write(stringsData)
    }
}
