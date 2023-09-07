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
}

// MARK: - shulffle

extension ProcessingFile: CodeShullffleProtocol {
    public func shulffle(_ order: Bool) {
        var codes = self.codes.map { shulffle($0, order: order) }
        if order {
            codes = codes.sorted(by: { $0.order < $1.order })
                .grouped { $0.order == $1.order }
                .map { $0.shuffled() }
                .flatMap { $0 }
        } else {
            codes = codes.shuffled()
        }
        self.codes = codes
    }

    public func shulffed(_ order: Bool) -> ProcessingFile {
        var codes = codes.map { shulffle($0, order: order) }
        if order {
            codes = codes.sorted(by: { $0.order < $1.order })
                .grouped { $0.order == $1.order }
                .map { $0.shuffled() }
                .flatMap { $0 }
        } else {
            codes = codes.shuffled()
        }
        let file = ProcessingFile(filePath: filePath, fileType: fileType)
        file.setCodes(codes)
        return file
    }
}

// MARK: - Name

extension ProcessingFile {
    public func renameCode(_ codeType: [CodeType], newName: String) {
        setCodes(codes.map { rawCode -> CodeRawProtocol in
            if let code = rawCode as? CodeContainerProtocol {
                return self.renameCodeInContainer(code, codeType: codeType, newName: newName)
            } else if let code = rawCode as? CodeProtocol, codeType.contains(code.type) {
                return code.asCode().renamed(newName)
            } else {
                return rawCode
            }
        })
    }

    public func renameCodeContainer(_ codeContainerType: [CodeContainerType], newName: String) {
        setCodes(codes.map { rawCode -> CodeRawProtocol in
            if let code = rawCode as? CodeContainerProtocol, codeContainerType.contains(code.type) {
                return self.renameCodeContainer(code, codeContainerType: codeContainerType, newName: newName)
            }
            return rawCode
        })
    }

    public func addOrReplacePrefixWithCode(_ codeType: [CodeType],
                                           prefix: String,
                                           separator: Character?)
    {
        setCodes(codes.map { rawCode -> CodeRawProtocol in
            if let code = rawCode as? CodeContainerProtocol {
                return self.addOrReplacePrefixWithCode(code, codeType: codeType, prefix: prefix, separator: separator)
            } else if let code = rawCode as? CodeProtocol, codeType.contains(code.type) {
                return code.asCode().replaceOrAddPrefrexToName(prefix, separator: separator)
            } else {
                return rawCode
            }
        })
    }

    public func addOrReplaceNameWithCodeContainer(_ codeContainerType: [CodeContainerType],
                                                  prefix: String,
                                                  separator: Character?)
    {
        setCodes(codes.map { rawCode -> CodeRawProtocol in
            if let code = rawCode as? CodeContainerProtocol, codeContainerType.contains(code.type) {
                return self.addOrReplacePrefixWithCodeContainer(code, codeContainerType: codeContainerType, prefix: prefix, separator: separator)
            }
            return rawCode
        })
    }

    // MARK: - Private

    private func renameCodeInContainer(_ codeContainer: CodeContainerProtocol,
                                       codeType: [CodeType],
                                       newName: String) -> CodeContainerProtocol
    {
        codeContainer
            .mapCodeContainer {
                self.renameCodeInContainer($0, codeType: codeType, newName: newName)
            }
            .mapCode(codeType, block: {
                $0.asCode().renamed(newName)
            })
            .asCodeContainer()
    }

    private func renameCodeContainer(_ codeContainer: CodeContainerProtocol,
                                     codeContainerType: [CodeContainerType],
                                     newName: String) -> CodeContainerProtocol
    {
        codeContainer
            .mapCodeContainer(codeContainerType, block: {
                self.renameCodeContainer($0, codeContainerType: codeContainerType, newName: newName)
            })
            .asCodeContainer()
            .renamed(newName)
    }

    private func addOrReplacePrefixWithCode(_ codeContainer: CodeContainerProtocol,
                                            codeType: [CodeType],
                                            prefix: String,
                                            separator: Character?) -> CodeContainerProtocol
    {
        codeContainer
            .mapCodeContainer {
                self.addOrReplacePrefixWithCode($0, codeType: codeType, prefix: prefix, separator: separator)
            }
            .mapCode(codeType, block: {
                $0.asCode().replaceOrAddPrefrexToName(prefix, separator: separator)
            })
            .asCodeContainer()
    }

    private func addOrReplacePrefixWithCodeContainer(_ codeContainer: CodeContainerProtocol,
                                                     codeContainerType: [CodeContainerType],
                                                     prefix: String,
                                                     separator: Character?) -> CodeContainerProtocol
    {
        codeContainer
            .mapCodeContainer(codeContainerType, block: {
                self.addOrReplacePrefixWithCodeContainer($0,
                                                         codeContainerType: codeContainerType,
                                                         prefix: prefix,
                                                         separator: separator)
            })
            .asCodeContainer()
            .replaceOrAddPrefrexToName(prefix, separator: separator)
    }
}
