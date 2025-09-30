//
//  ObfuscationModel.swift
//  Command
//
//  Created by mayong on 2023/9/26.
//

import Foundation

struct ObfuscationReplace: Codable {
    
    let map: [String: String]?
    
    let onlyPrefix: Bool?
    
    let onlyFilename: Bool?
    
    init(
        _ map: [String : String]? = nil,
        onlyPrefix: Bool? = nil,
        onlyFilename: Bool? = nil
    ) {
        self.map = map
        self.onlyPrefix = onlyPrefix
        self.onlyFilename = onlyFilename
    }
}

struct ObfuscationShuffule: Codable {
    let order: Bool?
}

struct ObfuscationZip: Codable {
    let name: String?
    let password: String?
    let newPassword: String?
}

struct ObfuscationCamelToSnake: Codable {
    let prefix: String
    
    let toLowercase: Bool?
}

struct ObfuscationConfig: Codable {

    let replace: ObfuscationReplace?
    
    let shuffule: ObfuscationShuffule?
    
    let camelToSnake: [ObfuscationCamelToSnake]?

    let snameToCamel: [ObfuscationCamelToSnake]?

    let zips: [ObfuscationZip]?
    
    let input: String?
        
    let output: String?
    
    let keepDirectory: Bool?
}
