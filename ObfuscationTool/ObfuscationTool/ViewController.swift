//
//  ViewController.swift
//  ObfuscationTool
//
//  Created by mayong on 2023/8/18.
//

import Cocoa
import ProcessingFiles
import SwiftFilePlugin
import FilePath
import SwiftString

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        testProcessingFile()
    }
    
    func testProcessingFile() {
        let filePath = Directory.desktop.appendFileName("SwiftFileIdentifierCache", ext: ".swift")
        let swiftFilePlugin = SwiftFileProcessingPlugin()
        let processingManager = ProcessingManager(path: filePath)
        processingManager.registerPlugin(swiftFilePlugin, forFileType: .fSwift)
        do {
            let files = processingManager.processing()
            let fileString = try files.map({ try $0.getContent() }).joined()
            let lines = try files.map({ try $0.lines() })
            let classes = files.map({ $0.getCodeContainer(.class).map(\.rawName).joined() }).joined()
            print(fileString)
            print("lines = \(lines)")
            print("classes = \(classes)")
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

