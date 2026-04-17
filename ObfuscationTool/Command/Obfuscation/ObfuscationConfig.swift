//
//  ObfuscationModel.swift
//  Command
//
//  Created by mayong on 2023/9/26.
//

import Foundation

struct ObfuscationTargets: Codable {
    /// 是否作用于文件路径/文件名（rename / move）
    let path: Bool?
    /// 是否作用于文件内容（rewrite content）
    let content: Bool?
}

struct ObfuscationReplace: Codable {
    
    let map: [String: String]?
    
    let onlyPrefix: Bool?
    
    let onlyFilename: Bool?

    /// 默认同时作用于 path+content；可分别关闭
    let targets: ObfuscationTargets?
    
    init(
        _ map: [String : String]? = nil,
        onlyPrefix: Bool? = nil,
        onlyFilename: Bool? = nil,
        targets: ObfuscationTargets? = nil
    ) {
        self.map = map
        self.onlyPrefix = onlyPrefix
        self.onlyFilename = onlyFilename
        self.targets = targets
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

    /// 默认同时作用于 path+content；可分别关闭
    let targets: ObfuscationTargets?
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
