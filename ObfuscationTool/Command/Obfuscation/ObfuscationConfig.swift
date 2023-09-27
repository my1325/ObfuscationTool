//
//  ObfuscationModel.swift
//  Command
//
//  Created by mayong on 2023/9/26.
//

import Foundation

protocol ObfuscationDefaultCompatible {
    associatedtype D
    
    static var `default`: D { get }
}

@propertyWrapper
struct ObfuscationDefaultCodable<D: ObfuscationDefaultCompatible>: Codable where D.D: Codable {
    static var `default`: Self { Self(wrappedValue: D.default) }
    
    var rawValue: D.D
    init(wrappedValue: D.D) {
        self.rawValue = wrappedValue
    }
    
    var wrappedValue: D.D {
        get {
            rawValue
        } set {
            rawValue = newValue
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = (try? container.decode(D.D.self)) ?? D.default
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct ObfuscationDefaultFalse: ObfuscationDefaultCompatible {
    typealias D = Bool
    
    static var `default`: Bool { false }
}

struct ObfuscationDefaultFloat1: ObfuscationDefaultCompatible {
    typealias D = Float
    
    static var `default`: Float { 1 }
}

struct ObfuscationDefaultEmptyString: ObfuscationDefaultCompatible {
    typealias D = String
    
    static var `default`: String { "" }
}

struct ObfuscationDefaultEmptyDictionary: ObfuscationDefaultCompatible {
    typealias D = [String: String]
    
    static var `default`: [String: String] { [:] }
}

typealias ObfuscationDefaultFalseCodeable = ObfuscationDefaultCodable<ObfuscationDefaultFalse>
typealias ObfuscationDefault1Codeable = ObfuscationDefaultCodable<ObfuscationDefaultFloat1>
typealias ObfuscationDefaultEmptyStringCodeable = ObfuscationDefaultCodable<ObfuscationDefaultEmptyString>
typealias ObfuscationDefaultEmptyDictionaryCodeable = ObfuscationDefaultCodable<ObfuscationDefaultEmptyDictionary>

struct ObfuscationReplace: ObfuscationDefaultCompatible, Codable {
    
    @ObfuscationDefaultEmptyDictionaryCodeable
    var prefix: [String: String]
    
    @ObfuscationDefaultFalseCodeable
    var handleFile: Bool
    
    @ObfuscationDefaultFalseCodeable
    var shouldAdd: Bool
    
    var enable: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case prefix
        case handleFile = "handle_file"
        case shouldAdd = "should_add"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._prefix = try container.decodeIfPresent(ObfuscationDefaultEmptyDictionaryCodeable.self, forKey: .prefix) ?? .default
        self._handleFile = try container.decodeIfPresent(ObfuscationDefaultFalseCodeable.self, forKey: .handleFile) ?? .default
        self._shouldAdd = try container.decodeIfPresent(ObfuscationDefaultFalseCodeable.self, forKey: .shouldAdd) ?? .default
        self.enable = true
    }
    
    init(prefix: [String: String], handleFile: Bool, shouldAdd: Bool) {
        self.prefix = prefix
        self.handleFile = handleFile
        self.shouldAdd = shouldAdd
    }
    
    static let `default` = ObfuscationReplace(prefix: [:], handleFile: false, shouldAdd: false)
}

struct ObfuscationShuffule: ObfuscationDefaultCompatible, Codable {
    @ObfuscationDefaultFalseCodeable
    var order: Bool = false
    
    var enable: Bool = false
    
    init(order: Bool) {
        self.order = order
    }
    
    static let `default` = ObfuscationShuffule(order: false)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._order = try container.decodeIfPresent(ObfuscationDefaultFalseCodeable.self, forKey: .order) ?? .default
        self.enable = true
    }
}

struct ObfuscationImage: ObfuscationDefaultCompatible, Codable {
    @ObfuscationDefault1Codeable
    var compress: Float = 1
    
    @ObfuscationDefaultFalseCodeable
    var md5: Bool = false
    
    var enable: Bool = false
    
    init(compress: Float, md5: Bool) {
        self.compress = compress
        self.md5 = md5
    }
    
    static let `default` = ObfuscationImage(compress: 1, md5: false)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._compress = try container.decodeIfPresent(ObfuscationDefault1Codeable.self, forKey: .compress) ?? .default
        self._md5 = try container.decodeIfPresent(ObfuscationDefaultFalseCodeable.self, forKey: .md5) ?? .default
        self.enable = true
    }
}

struct ObfuscationGit: Codable, ObfuscationDefaultCompatible {
    let url: String

    @ObfuscationDefaultEmptyStringCodeable
    var tag: String
    
    @ObfuscationDefaultEmptyStringCodeable
    var branch: String
    
    var enable: Bool = false
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try container.decode(String.self, forKey: .url)
        self._tag = try container.decodeIfPresent(ObfuscationDefaultEmptyStringCodeable.self, forKey: .tag) ?? .default
        self._branch = try container.decodeIfPresent(ObfuscationDefaultEmptyStringCodeable.self, forKey: .branch) ?? .default
        self.enable = true
    }
    
    init(url: String, tag: String = "", branch: String = "") {
        self.url = url
        self.tag = tag
        self.branch = branch
    }
    
    static let `default`: ObfuscationGit = ObfuscationGit(url: "")
}

typealias ObfuscationReplaceDefaultCodable = ObfuscationDefaultCodable<ObfuscationReplace>
typealias ObfuscationImageDefaultCodable = ObfuscationDefaultCodable<ObfuscationImage>
typealias ObfuscationShuffuleDefaultCodable = ObfuscationDefaultCodable<ObfuscationShuffule>
typealias ObfuscationGitDefaultCodable = ObfuscationDefaultCodable<ObfuscationGit>

struct ObfuscationConfig: Codable {
    @ObfuscationReplaceDefaultCodable
    var replace: ObfuscationReplace
    
    @ObfuscationShuffuleDefaultCodable
    var shuffule: ObfuscationShuffule
    
    @ObfuscationImageDefaultCodable
    var images: ObfuscationImage
    
    @ObfuscationDefaultEmptyStringCodeable
    var path: String
    
    @ObfuscationDefaultEmptyStringCodeable
    var name: String
    
    @ObfuscationGitDefaultCodable
    var git: ObfuscationGit
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._replace = try container.decodeIfPresent(ObfuscationReplaceDefaultCodable.self, forKey: .replace) ?? .default
        self._shuffule = try container.decodeIfPresent(ObfuscationShuffuleDefaultCodable.self, forKey: .shuffule) ?? .default
        self._images = try container.decodeIfPresent(ObfuscationImageDefaultCodable.self, forKey: .images) ?? .default
        self._path = try container.decodeIfPresent(ObfuscationDefaultEmptyStringCodeable.self, forKey: .path) ?? .default
        self._name = try container.decodeIfPresent(ObfuscationDefaultEmptyStringCodeable.self, forKey: .path) ?? .default
        self._git = try container.decodeIfPresent(ObfuscationGitDefaultCodable.self, forKey: .git) ?? .default
    }
}
