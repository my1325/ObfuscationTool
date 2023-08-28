//
//  File.swift
//
//
//  Created by mayong on 2023/8/28.
//

import Foundation
import SwiftString

public protocol ProcessedObject {
    var startLine: ProcessingLine { get }
    
    var name: SwiftString { get }
    
    var objects: [ProcessedObject] { get }
        
    func processingLine(_ line: ProcessingLine) -> Bool
}

internal final class DefaultBodyLineObject: ProcessedObject {
    let startLine: ProcessingLine
    
    let name: SwiftString
    
    let objects: [ProcessedObject] = []
    
    init(startLine: ProcessingLine) {
        self.startLine = startLine
        self.name = SwiftString(string: startLine.rawValue)
    }
    
    func processingLine(_ line: ProcessingLine) -> Bool { false }
}

protocol ProcessedObjectWithEnd: ProcessedObject {
    var isEnd: Bool { get }
}

internal final class DefaultDocumentBlockObject: ProcessedObjectWithEnd {
    let startLine: ProcessingLine
    
    let name: SwiftString
    
    var objects: [ProcessedObject] = []
    
    var isEnd: Bool = false
    
    init(startLine: ProcessingLine) {
        self.startLine = startLine
        self.name = SwiftString(string: startLine.identifier.rawValue)
    }
    
    func processingLine(_ line: ProcessingLine) -> Bool {
        guard !isEnd else { return false }
        switch line.identifier {
        case .iStop: isEnd = true
        case .iBody: objects.append(DefaultBodyLineObject(startLine: line))
        default: break
        }
        return true
    }
}

class DefaultProcessingObject: ProcessedObjectWithEnd {
    class var identifier: ProcessingIdentifier { .iNone }
    
    class var match: CommonProcessingIdentifierPattern { .classMatch }
    
    let startLine: ProcessingLine
    
    let name: SwiftString
    
    var objects: [ProcessedObject] = []
    
    init?(startLine: ProcessingLine) {
        guard startLine.identifier == Self.identifier,
              let name = SwiftString(string: startLine.output)
            .matches(Self.match)
              .first?
              .trim()
        else {
            return nil
        }
        self.startLine = startLine
        self.name = name
    }
    
    var isStart: Bool = false
    
    var isEnd: Bool = false
    
    var lastObject: ProcessedObjectWithEnd?
    
    @discardableResult
    func processingLine(_ line: ProcessingLine) -> Bool {
        guard !isEnd else { return false }
        guard !lastObjectHandleLineIfCould(line) else { return true }
        defer { lastObject = objects.last as? ProcessedObjectWithEnd }
        switch line.identifier {
        case .iStop: isEnd = true
        case .iBegin: isStart = true
        case .iBody, .iDocumentInline:
            objects.append(DefaultBodyLineObject(startLine: line))
        case .iDocumentBlock:
            objects.append(DefaultDocumentBlockObject(startLine: line))
        case .iFunc, .iStruct, .iEnum, .iClass, .iProperty, .iExtension:
            if let object = handleLineToObjects(line) {
                objects.append(object)
            }
        case .iNone, .iFile: break
        }
        return true
    }
    
    func lastObjectHandleLineIfCould(_ line: ProcessingLine) -> Bool {
        guard let lastObject, !lastObject.isEnd else { return false }
        return lastObject.processingLine(line)
    }
    
    func handleLineToObjects(_ line: ProcessingLine) -> ProcessedObjectWithEnd? {
        fatalError("need override")
    }
}

internal final class PropertyObject: DefaultProcessingObject {
    override class var identifier: ProcessingIdentifier { .iProperty }
    
    override class var match: CommonProcessingIdentifierPattern { .propertyMatch }
}

internal final class FuncObject: DefaultProcessingObject {
    override class var identifier: ProcessingIdentifier { .iFunc }
    
    override class var match: CommonProcessingIdentifierPattern { .funcMatch }
}

internal class ClassObject: DefaultProcessingObject {
    override class var identifier: ProcessingIdentifier { .iClass }
    
    override class var match: CommonProcessingIdentifierPattern { .classMatch }
    
    override func handleLineToObjects(_ line: ProcessingLine) -> ProcessedObjectWithEnd? {
        switch line.identifier {
        case .iFunc: return FuncObject(startLine: line)
        case .iProperty: return PropertyObject(startLine: line)
        case .iClass: return ClassObject(startLine: line)
        case .iStruct: return StructObject(startLine: line)
        case .iEnum: return EnumObject(startLine: line)
        case .iExtension: return ExtensionObject(startLine: line)
        default: return nil
        }
    }
}

internal final class StructObject: ClassObject {
    override class var identifier: ProcessingIdentifier { .iStruct }
    
    override class var match: CommonProcessingIdentifierPattern { .structMatch }
}

internal final class EnumObject: ClassObject {
    override class var identifier: ProcessingIdentifier { .iEnum }
    
    override class var match: CommonProcessingIdentifierPattern { .enumMatch }
}

internal final class ExtensionObject: ClassObject {
    override class var identifier: ProcessingIdentifier { .iExtension }
    
    override class var match: CommonProcessingIdentifierPattern { .extensionMatch }
}
