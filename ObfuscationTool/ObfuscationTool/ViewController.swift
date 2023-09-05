//
//  ViewController.swift
//  ObfuscationTool
//
//  Created by mayong on 2023/8/18.
//

import Cocoa
//import ProcessingFiles
import SwiftFilePlugin
import FilePath

import SwiftString
import SwiftSyntax
import SwiftParser

public extension Array {
    func grouped(_ by: @escaping (Element, Element) -> Bool) -> [[Element]] {
        var retValue: [[Element]] = Array<[Element]>(repeating: [], count: count)
        var length = 0
        for e in self {
            var i = 0
            while i < length {
                var subValue = retValue[i]
                if by(e, subValue[0]) { break }
                i += 1
            }
            var subValue = retValue[i]
            subValue.append(e)
            retValue[i] = subValue
            if i == length { length += 1 }
        }
        return retValue.prefix(upTo: length).map({ $0 })
    }
}

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
//        testSwiftSyntax()
        testProcessingFile()
    }
    
    func testProcessingFile() {
//        let filePath = Directory.desktop.appendFileName("SwiftFileIdentifierCache", ext: ".swift")
//        let swiftFilePlugin = SwiftFileProcessingPlugin()
//        let processingManager = ProcessingManager(path: filePath)
//        processingManager.registerPlugin(swiftFilePlugin, forFileType: .fSwift)
//        processingManager.delegate = self
//        let fileString = processingManager.startParse()
//        print(fileString)
        let test = [1,2,3,4,5,1,2,3,5,6,3,2,4,5,2,1,1,2,1,2,3,4,5,6,7]
        let grouped = test.grouped({ $0 == $1 })
        print(grouped)
    }
    
//    func processingManager(_ manager: ProcessingFiles.ProcessingManager, didProcessedFile file: ProcessingFiles.ProcessingFile) {
//
//    }
    
    class CustomVisitor: SyntaxAnyVisitor {
        var classTokens: [TokenSequence] = []
        var importTokens: [TokenSequence] = []
        var funcTokens: [TokenSequence] = []
        var variableTokens: [TokenSequence] = []
        var initTokens: [TokenSequence] = []
        var caseTokens: [TokenSequence] = []
//        override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
//            tokens.append(contentsOf: node.tokens(viewMode: .all))
//            return .visitChildren
//        }
        
        override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
            let child = node.children(viewMode: .sourceAccurate).first
            var optionalToken = child?.nextToken(viewMode: .sourceAccurate)
            var tokenString: String = ""
            while let token = optionalToken, token.tokenKind != .leftBrace {
                tokenString = tokenString.appendingFormat("%@%@%@", token.leadingTrivia.description, token.text, token.trailingTrivia.description)
                optionalToken = token.nextToken(viewMode: .sourceAccurate)
            }
            print(tokenString)
//            enumTokens.append(node.tokens(viewMode: .sourceAccurate))
            return .visitChildren
        }
        
        override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
            caseTokens.append(node.tokens(viewMode: .sourceAccurate))
            return .skipChildren
        }
        
        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            print(node.name)
            classTokens.append(node.tokens(viewMode: .sourceAccurate))
            return .skipChildren
        }
        
        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            funcTokens.append(node.tokens(viewMode: .sourceAccurate))
            return .skipChildren
        }
        
        override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
            importTokens.append(node.tokens(viewMode: .sourceAccurate))
            return .skipChildren
        }
        
        override func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
//            node.clauses.tokens(viewMode: .sourceAccurate)
            importTokens.append(node.tokens(viewMode: .sourceAccurate))
            return .skipChildren
        }
        
        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            variableTokens.append(node.tokens(viewMode: .sourceAccurate))
            return .skipChildren
        }
        
        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            funcTokens.append(node.tokens(viewMode: .sourceAccurate))
            return .skipChildren
        }
    }
    
    func testSwiftSyntax() {
        let url = URL(fileURLWithPath: "/Users/my/Desktop/SwiftFileIdentifierCache.swift")
//        let url = URL(fileURLWithPath: "/Users/mayong/Desktop/ObfuscationTool/ObfuscationTool/ProcessingFiles/Sources/SwiftFilePlugin/SwiftFileIdentifierCache.swift")
        do {
            let data = try Data(contentsOf: url)
            if let source = String(data: data, encoding: .utf8) {
                var parser = Parser(source)
                let tree = SourceFileSyntax.parse(from: &parser)
                let visitor = CustomVisitor(viewMode: .all)
                visitor.walk(tree)
                for enumTokens in visitor.caseTokens {
                    var enumString: String = ""
                    for token in enumTokens {
                        enumString = enumString.appendingFormat("%@%@%@", token.leadingTrivia.description, token.text, token.trailingTrivia.description)
                    }
                    print(enumString)
                }
//                for classToken in visitor.classTokens {
//                    var classString: String = ""
//                    for token in classToken {
//                        classString = classString.appendingFormat("%@%@%@", token.leadingTrivia.description, token.text, token.trailingTrivia.description)
//                    }
//                    print(classString)
//                }
//                for importToken in visitor.importTokens {
////                    print(importToken.)
//                    var importString: String = ""
//                    for token in importToken {
////                        print(token.tokenKind)
//                        importString = importString.appendingFormat("%@%@%@", token.leadingTrivia.description, token.text, token.trailingTrivia.description)
//                    }
//                    print(importString)
//                }
//                print("start parse a func token")
//                for funcTokens in visitor.funcTokens {
//                    var funcString: String = ""
//                    for tokens in funcTokens {
//                        funcString = funcString.appendingFormat("%@%@%@", tokens.leadingTrivia.description, tokens.text, tokens.trailingTrivia.description)
//                    }
//                    print(funcString)
//                }
//                print("start parse variable")
//                for varTokens in visitor.variableTokens {
//                    var varString: String = ""
//                    for tokens in varTokens {
//                        varString = varString.appendingFormat("%@%@%@", tokens.leadingTrivia.description, tokens.text, tokens.trailingTrivia.description)
//                    }
//                    print(varString)
//                }
            }
        } catch {
            print(error)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

