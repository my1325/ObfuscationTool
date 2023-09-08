//
//  File.swift
//
//
//  Created by my on 2023/9/2.
//

import CodeProtocol
import FilePath
import Foundation

public enum FileType {
    /// .swift
    case fSwift
    /// .h
    case fHeader
    /// .m
    case fImplemention
    /// other
    case other

    init(ext: String) {
        switch ext {
        case "h": self = .fHeader
        case "swift": self = .fSwift
        case "m": self = .fImplemention
        default: self = .other
        }
    }
}

public final class ProcessingFile {
    public let filePath: FilePath
    public let fileType: FileType
    public init(filePath: FilePath, fileType: FileType) {
        self.filePath = filePath
        self.fileType = fileType
    }

    public func getContent() throws -> String {
        guard !codes.isEmpty else { return try filePath.readLines().joined() }
        return codes.map(\.content).joined()
    }

    public private(set) var codes: [CodeRawProtocol] = []
    public func setCodes(_ codes: [CodeRawProtocol]) {
        self.codes = codes
    }

    public func lines(_ trimWhiteSpaceLine: Bool = false) throws -> Int {
        try getContent()
            .components(separatedBy: .newlines)
            .filter { !trimWhiteSpaceLine || !$0.isEmpty }
            .count
    }

    public func getCodeContainer(_ type: CodeContainerType) -> [CodeContainerProtocol] {
        codes.map { $0.asCodeContainer(type) }
            .filter { $0 != nil }
            .map { $0! }
    }

    public func getCode(_ type: CodeType) -> [CodeProtocol] {
        codes.map { $0.asCode(type) }
            .filter { $0 != nil }
            .map { $0! }
    }
    
    public func newFileWithCode(_ newCode: [CodeRawProtocol]) -> ProcessingFile {
        let file = ProcessingFile(filePath: filePath, fileType: fileType)
        file.setCodes(newCode)
        return file
    }
}
