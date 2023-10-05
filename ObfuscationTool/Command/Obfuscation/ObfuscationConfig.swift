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
    
    init(map: [String : String]?, handleFile: Bool?) {
        self.map = map
        self.handleFile = handleFile
    }
    
    static let `default` = ObfuscationReplace(map: nil, handleFile: nil)
    
    func getName(_ origin: String) -> String {
        map?.reduce(origin) { $0.replacingOccurrences(of: $1.key, with: $1.value) } ?? origin
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
    
    init(prefix: String?, separator: String?, handleFile: Bool?, shouldAdd: Bool?) {
        self.prefix = prefix
        self.separator = separator
        self.handleFile = handleFile
        self.shouldAdd = shouldAdd
    }
    
    static let `default` = ObfuscationPrefix(prefix: nil, separator: nil, handleFile: nil, shouldAdd: nil)
    
    func getName(_ origin: String) -> String {
        guard let prefix else { return origin }
        let separator = separator?.first ?? "-"
        let shouldAdd = shouldAdd ?? false
        let prefixString = String(format: "%@%@", prefix, String(separator))
        if origin.hasPrefix(prefixString) {
            let startIndex = origin.index(origin.startIndex, offsetBy: prefixString.count)
            return String(format: "%@%@", prefixString, String(origin[startIndex ..< origin.endIndex]))
        } else if shouldAdd {
            return String(format: "%@%@", prefixString, origin)
        } else {
            return origin
        }
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

struct ObfuscationZip: Codable {
    let name: String?
    let password: String?
    let newPassword: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case password
        case newPassword = "new_password"
    }
}

struct ObfuscationConfig: Codable {

    let replace: ObfuscationReplace?
    
    let prefix: ObfuscationPrefix?
    
    let shuffule: ObfuscationShuffule?
    
    let images: ObfuscationImage?
    
    let zips: [ObfuscationZip]?
    
    let path: String?
    
    let name: String?
    
    let git: ObfuscationGit?
    
    let output: String?
}
