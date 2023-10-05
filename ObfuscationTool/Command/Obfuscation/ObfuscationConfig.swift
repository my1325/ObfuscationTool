//
//  ObfuscationModel.swift
//  Command
//
//  Created by mayong on 2023/9/26.
//

import Foundation

struct ObfuscationReplace: Codable {
    
    let map: [String: String]?
    
    let handleFile: Bool?
    
    enum CodingKeys: String, CodingKey {
        case map
        case handleFile = "handle_file"
    }
}

struct ObfuscationPrefix: Codable {
    let prefix: String?
    
    let separator: String?
    
    let handleFile: Bool?
    
    let shouldAdd: Bool?
        
    enum CodingKeys: String, CodingKey {
        case prefix
        case separator
        case handleFile = "handle_file"
        case shouldAdd = "should_add"
    }
}

struct ObfuscationShuffule: Codable {
    let order: Bool?
}

struct ObfuscationImage: Codable {
    
    let compress: Float?
    
    let md5: Bool?
}

struct ObfuscationGit: Codable {
    let url: String?

    let tag: String?
    
    let branch: String?
}

struct ObfuscationConfig: Codable {

    let replace: ObfuscationReplace?
    
    let prefix: ObfuscationPrefix?
    
    let shuffule: ObfuscationShuffule?
    
    let images: ObfuscationImage?
    
    let path: String?
    
    let name: String?
    
    let git: ObfuscationGit?
    
    let output: String?
}
