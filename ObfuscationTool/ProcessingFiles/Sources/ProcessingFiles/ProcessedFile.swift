//
//  File.swift
//  
//
//  Created by mayong on 2023/8/28.
//

import Foundation

// iClass class-name iEnd
// iBegin
// iEmpty
// iDocument
// iProperty property-name iEnd
// iBegin
// ...Code
// iStop
// iEmpty
// iDocument
// iFunc func-name iEnd
// iBegin
// iStop
// iStop
public enum ProcessingIdentifier: String {
    case iNone
    
    case iBody
    
    case iFile
    case iClass
    case iEnum
    case iStruct
    
    case iExtension
    
    case iBegin
    case iStop
    
    case iProperty
    case iFunc

    case iDocumentInline
    case iDocumentBlock
}

public protocol ProcessingLine {
    
    var rawValue: String { get }
    
    var identifier: ProcessingIdentifier { get }
    
    var output: String { get }
}

public protocol ProcessingFile {
    var lines: [ProcessingLine] { get }
}

struct DefaultFileMarkLine: ProcessingLine {
    let rawValue: String = ""
    let output: String
    let identifier: ProcessingIdentifier
    init(identifier: ProcessingIdentifier = .iFile, output: String = "iFile File iEnd") {
        self.output = output
        self.identifier = identifier
    }
}

internal final class ProcessedFileObject: DefaultProcessingObject {
    override class var identifier: ProcessingIdentifier { .iFile }
    
    override class var match: CommonProcessingIdentifierPattern { .fileMatch }
    
    init() {
        super.init(startLine: DefaultFileMarkLine())!
    }
}

public final class ProcessedFile {
    let fileObject: ProcessedFileObject = ProcessedFileObject()
    public let processingFile: ProcessingFile
    public init(processingFile: ProcessingFile) {
        self.processingFile = processingFile
    }
    
    public func makeProcessedObjects() -> [ProcessedObject] {
        var lines = processingFile.lines
        lines.append(DefaultFileMarkLine(identifier: .iStop, output: ProcessingIdentifier.iStop.rawValue))
        for line in lines {
            fileObject.processingLine(line)
        }
        return fileObject.objects
    }
}
