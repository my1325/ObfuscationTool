//
//  File.swift
//
//
//  Created by mayong on 2023/8/29.
//

import Foundation
import ProcessingFiles
import SwiftString
import UIKit

protocol SwiftProcessingLine: ProcessingLine {
    func processingLines(_ lines: [SwiftString], at: inout Int) throws
}

internal class SwiftProcessingLineParser: SwiftProcessingLine {
    var rawValue: String = ""

    var identifier: ProcessingIdentifier { .iEmpty }

    var name: String = ""

    var lines: [ProcessingLine] = []

    func processingLines(_ lines: [SwiftString], at: inout Int) throws {
        fatalError()
    }

    class func lineParserWithLine(_ line: SwiftString) throws -> SwiftProcessingLineParser? {
        if line.trim().string.hasPrefix(SwiftFilePatterns.patternClass.identifier) {
            return SwiftClassProcessingLineParser()
        } else if line.trim().string.hasPrefix(SwiftFilePatterns.patternFunc.identifier) {
            return SwiftFuncProcessingLineParser()
        } else if line.trim().string.hasPrefix(SwiftFilePatterns.patternProperty.identifier) {
            return SwiftPropertyProcessingLineParser()
        } else if try line.matchCount(SwiftFilePatterns.patternMacroWraning.pattern) > 0 {
            return SwiftJustProcessingLineParser()
        } else if try line.matchCount(SwiftFilePatterns.patternMacroError.pattern) > 0 {
            return SwiftJustProcessingLineParser()
        } else if try line.matchCount(SwiftFilePatterns.patternImport.pattern) > 0 {
            return SwiftJustProcessingLineParser()
        } else if try line.matchCount(SwiftFilePatterns.patternMacroIf.pattern) > 0 {
            return SwiftMacroIFProcessingLineParser()
        } else {
            return nil
        }
    }
}

internal final class SwiftMacroIFProcessingLineParser: SwiftProcessingLineParser {
    override var identifier: ProcessingIdentifier { .iCode }

    override func processingLines(_ lines: [SwiftString], at: inout Int) throws {
        var count = -1
        while at < lines.count, count != 0 {
            let line = lines[at]
            let ifCount = try line.matchCount(SwiftFilePatterns.patternMacroIf.pattern)
            count = count == -1 ? ifCount : count + ifCount
            let endIfCount = try line.matchCount("#endif")
            count -= ifCount
            rawValue.append(line.string)
            at += 1
        }
    }
}

internal final class SwiftHeaderProcessingLineParser: SwiftProcessingLineParser {}

internal final class SwiftDocumentProcessingLineParser: SwiftProcessingLineParser {}

internal final class SwiftClassProcessingLineParser: SwiftProcessingLineParser {
    override var identifier: ProcessingIdentifier { .iClass }

    override func processingLines(_ lines: [SwiftString], at: inout Int) throws {
        let startIndex = at
        var classCount = -1
        rawValue.append(lines[at].string)
        while at < lines.count, classCount != 0 {
            let line = lines[at]
            let bCount = try line.matchCount("{")
            let eCount = try line.matchCount("}")
            classCount = classCount == -1 ? bCount : classCount + bCount
            classCount -= eCount

            if classCount > 0,
               at > startIndex,
               let parserLine = try SwiftProcessingLineParser.lineParserWithLine(line)
            {
                try parserLine.processingLines(lines, at: &at)
                self.lines.append(parserLine)
            } else {
                at += 1
            }
        }
    }
}

internal final class SwiftPropertyProcessingLineParser: SwiftProcessingLineParser {
    override var identifier: ProcessingIdentifier { .iProperty }
    
    override func processingLines(_ lines: [SwiftString], at: inout Int) throws {
        var isEnd: Bool = false
        while at < lines.count, isEnd {
            let line = lines[at]
            rawValue.append(line.string)
            if line.trim().string.hasSuffix("{") {
                
            }
        }
    }
}

internal final class SwiftFuncProcessingLineParser: SwiftProcessingLineParser {
    override var identifier: ProcessingIdentifier { .iFunc }
    
    override func processingLines(_ lines: [SwiftString], at: inout Int) throws {
        var classCount = -1
        while at < lines.count, classCount != 0 {
            let line = lines[at]
            rawValue.append(line.string)
            let bCount = try line.matchCount("{")
            let eCount = try line.matchCount("}")
            classCount = classCount == -1 ? bCount : classCount + bCount
            classCount -= eCount
            at += 1
        }
    }
}

internal final class SwiftJustProcessingLineParser: SwiftProcessingLineParser {
    override var identifier: ProcessingIdentifier { .iCode }

    override func processingLines(_ lines: [SwiftString], at: inout Int) throws {
        rawValue.append(lines[at].string)
        at += 1
    }
}
