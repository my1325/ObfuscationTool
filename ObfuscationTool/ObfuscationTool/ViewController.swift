//
//  ViewController.swift
//  ObfuscationTool
//
//  Created by mayong on 2023/8/18.
//

import Cocoa
//import ProcessingFiles
import SwiftString
import SourceKittenFramework
import SwiftSyntax
import SwiftParser

class ViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        testSwiftSyntax()
    }
    
    class CustomVisitor: SyntaxAnyVisitor {
        var tokens: [TokenSyntax] = []
//        override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
//            tokens.append(contentsOf: node.tokens(viewMode: .all))
//            return .visitChildren
//        }
        
        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            return .visitChildren
        }
        
        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            tokens.append(node.firstToken(viewMode: .sourceAccurate)!)
            for token in tokens {
                print(token)
            }
            return .skipChildren
        }
    }
    
    func testSwiftSyntax() {
        let url = URL(fileURLWithPath: "/Users/mayong/Desktop/ObfuscationTool/ObfuscationTool/ProcessingFiles/Sources/SwiftFilePlugin/SwiftFileIdentifierCache.swift")
        do {
            let data = try Data(contentsOf: url)
            if let source = String(data: data, encoding: .utf8) {
                var parser = Parser(source)
                let tree = SourceFileSyntax.parse(from: &parser)
                let visitor = CustomVisitor(viewMode: .all)
                visitor.walk(tree)

            }
        } catch {
            print(error)
        }
    }
    
    func sendRequest() {
        guard let file = File(path: "/Users/mayong/Desktop/ObfuscationTool/ObfuscationTool/ProcessingFiles/Sources/SwiftFilePlugin/SwiftFileIdentifierCache.swift") else {
            return
        }
        let request = Request.syntaxTree(file: file, byteTree: true)
        do {
            let response = try request.send()
            print(response)
        } catch let e {
            print(e)
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

