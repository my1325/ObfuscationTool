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
import Plugins

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        testProcessingFile()
    }
    
    func testProcessingFile() {
        let filePath = DirectoryPath.desktop.appendFileName("ObfuscationToolTest", ext: "swift")
        let plugin = FileStringHandlePlugin([.prefix(mode: .addOrReplace, prefix: "ot", separator: "_")])
        let processingManager = ProcessingManager(path: filePath, fileHandlePlugins: [plugin])
        processingManager.registerPlugin(SwiftFileProcessingPlugin(), forFileType: .fSwift)
        do {
            let files = processingManager.processing()
//            let lines = try files.map({ try $0.lines() }).reduce(0, +)
//            let classes = files.map({ $0.getCodeContainer(.class).map(\.rawName).joined() }).joined()
//            print("lines = \(lines)")
//            print("classes = \(classes)")
            
            let fileString = try files.map({ try $0.getContent() }).joined()
            print(fileString)
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

