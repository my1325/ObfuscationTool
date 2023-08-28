//
//  File.swift
//  
//
//  Created by mayong on 2023/8/28.
//

import Foundation
import ProcessingFiles
import FilePath
import SwiftString

struct SwiftProcessingFile: ProcessingFile {
    let lines: [ProcessingLine]
}

struct SwiftProcessingLine: ProcessingLine {
    let rawValue: String
    let output: String
    let identifier: ProcessingIdentifier
}

open class SwiftFilePlugin: ProcessingFilePlugin {
    
    struct SwiftStringIdentifier {
        let identifier: String
        let pattern: String
        
        static let identifierPrefix: String = "SWIFT_FILE_IDENTIFIER_"
        static let string = SwiftStringIdentifier(identifier: String(format: " %@_STRING ", identifierPrefix), pattern: "\".*\"")
        static let mulitString = SwiftStringIdentifier(identifier: String(format: " %@_MULTI_LINE_STRING ", identifierPrefix), pattern: "\"\"\"([\\s\\S]*).*\"\"\"")
//        static let codeBegin = SwiftStringIdentifier(identifier: String(format: " %@_BEGIN ", identifierPrefix), pattern: "{")
//        static let codeEnd = SwiftStringIdentifier(identifier: String(format: " %@_END ", identifierPrefix), pattern: "}")
        static let documentInline = SwiftStringIdentifier(identifier: String(format: " %@_DOCUMENT_INLINE ", identifierPrefix), pattern: "//.*")
        static let documentBlock = SwiftStringIdentifier(identifier: String(format: " %@_DOCUMENT_BLOCK ", identifierPrefix), pattern: "/\\*([\\s\\S]*).*\\*/")
    }
    
    @objc
    private
    var
code
    :
    String = ""
    // var abc: String ---- (var|let)( |\n)+\w+( |\n)*           :( |\n)*\w+( |\n)*
    // var abc: String = ""    ----- (var|let)( |\n)+\w+( |\n)*  :( |\n)*\w+( |\n)*=( |\n)*.*
    // var abc: String { } ----  (var|let)( |\n)+\w+( |\n)*       :( |\n)*\w+( |\n)*\{[\s\S]*\}
    // var abc: String = "" { } ---- (var|let)( |\n)+\w+( |\n)*   :( |\n)*\w+( |\n)*=( |\n)*.*( |\n)*\{[\s\S]*\}
    
    // var abc = "" ---- (var|let)( |\n)+\w+( |\n)*                =( |\n)*.*
    // var abc = "" { } ---- (var|let)( |\n)+\w+( |\n)*            =( |\n)*.*\{[\s\S]*\}
    // var abc: String = {}() --- (var|let)( |\n)+\w+( |\n)*     =( |\n)*\{[\s\S]*\}( |\n)*\(.*\)
    
    // (var|let)( |\n)+\w+( |\n)*((:( |\n)*\w+( |\n)*((=( |\n)*.*)|(\{[\s\S]*\})|(=( |\n)*.*( |\n)*\{[\s\S]*\})))|(=( |\n)*((.*)|(.*\{[\s\S]*\})|(\{[\s\S]*\}( |\n)*\(.*\)))))
    
//    (@\w+( |\n)+)?((public|private|fileprivate|open|internal)( |\n)+)?(override( |\n)+)?((class|static)( |\n)+)?(var( |\n)+\w+( |\n)*(:( |\n)*\w+))?
    // (@\w+( |\n)+)?((public|private|fileprivate|open|internal)( |\n)+)?(override( |\n)+)?((class|static)( |\n)+)?func +\w+( |\n)*\([\s\S]*\)(( |\n)*->( |\n)*\w+)?
    public
    func processingManager(_ manager: ProcessingManager, processedFile file: FilePath) -> ProcessingFile {
        let lines = linesForFile(file)
        return SwiftProcessingFile(lines: lines)
    }
    
    public func linesForFile(_ file: FilePath) -> [ProcessingLine] {
        do {
            let fileString = try file.readLines().joined()
            let stringLines = try prehandleLineString(fileString)
            var lines: [ProcessingLine] = []
            
            
            var beginCount: Int = 0
            for stringLine in stringLines {
                let trimString = stringLine.trim()
                beginCount += try trimString.matchCount("{")
                beginCount -= try trimString.matchCount("}")
                // handleCode
                
                let formattedLine = Array(repeating: "\t", count: beginCount)
                    .joined()
                    .appendingFormat("%@\n", trimString.string)
            }
            
            return lines
        } catch {
            debugPrint(error)
            return []
        }
    }
    
    private var identifierCache: [SwiftString] = []
    
    private let replaceIdentifiers: [SwiftStringIdentifier] = [.string, .mulitString, .documentInline, .documentBlock]
    
    private func prehandleLineString(_ lineString: String) throws -> [SwiftString] {
        let originString = SwiftString(string: lineString)
        identifierCache = try replaceIdentifiers.map({ try originString.matches($0.pattern) }).flatMap({ $0 })
        let swiftString = try replaceIdentifiers.reduce(originString, { try $0.replaceWithMatches($1.pattern, with: $1.identifier) })
        return swiftString.split().map({ SwiftString(string: $0) })
    }
}
