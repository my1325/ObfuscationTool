//
//  File.swift
//
//
//  Created by mayong on 2023/8/28.
//

import FilePath
import Foundation
import ProcessingFiles
import SwiftString

open class SwiftFilePlugin: ProcessingFilePlugin {
    public func processingManager(_ manager: ProcessingManager, processedFile file: FilePath) throws -> [ProcessingLine] {
        try linesForFile(file)
    }

    public func linesForFile(_ file: FilePath) throws -> [ProcessingLine] {
        let fileString = try file.readLines().joined()
        let stringLines = try prehandleLineString(fileString)
        var lines: [ProcessingLine] = []
        var index: Int = 0
        while index < stringLines.count {
            let line = stringLines[index]
            if let parser = try SwiftProcessingLineParser.lineParserWithLine(line) {
                try parser.processingLines(stringLines, at: &index)
                lines.append(parser)
            } else {
                index += 1
            }
        }
        return lines
    }

    private var identifierCache: [SwiftFilePatterns: SwiftFileIdentifierCache] = [
        .patternString: SwiftFileIdentifierCache(identifier: .patternString),
        .patternMultiString: SwiftFileIdentifierCache(identifier: .patternMultiString),
        .patternDocumentInline: SwiftFileIdentifierCache(identifier: .patternDocumentInline),
        .patternDocumentBlock: SwiftFileIdentifierCache(identifier: .patternDocumentBlock),
        .patternClass: SwiftFileIdentifierCache(identifier: .patternClass),
        .patternFunc: SwiftFileIdentifierCache(identifier: .patternFunc),
        .patternProperty: SwiftFileIdentifierCache(identifier: .patternProperty)
    ]

    private let replaceIdentifiers: [SwiftFilePatterns] = [.patternString, .patternMultiString, .patternDocumentInline, .patternDocumentBlock, .patternClass, .patternFunc, .patternProperty]

    private func prehandleLineString(_ lineString: String) throws -> [SwiftString] {
        let originString = SwiftString(string: lineString)
        try replaceIdentifiers.forEach({
            let matches = try originString.matches($0.pattern)
            let cache = identifierCache[$0]
            cache?.resetCache(matches)
        })
        let swiftString = try replaceIdentifiers.reduce(originString) { try $0.replaceWithMatches($1.pattern, with: $1.identifier) }
        return swiftString.split().map { SwiftString(string: $0) }
    }
}
