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
import Plugins
import SnapKit
import Combine

class ViewController: NSViewController {
    private lazy var segmentedControl: SegmentedControl = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.items = ["Confusion", "Crypt"]
        self.view.addSubview($0)
        $0.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(0)
            make.height.equalTo(40)
        }
        return $0
    }(SegmentedControl(frame: .zero))
    
    var sinkStore: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.$selectedIndex.sink(receiveValue: {
            print($0)
        }).store(in: &sinkStore)
    }
    
    func testProcessingFile() {
        let filePath = DirectoryPath.desktop.appendFileName("ObfuscationToolTest", ext: "swift")
        let prefixPlugin = FileStringHandlePlugin([.prefix(mode: .addOrReplace, prefix: "ot", separator: "_")], codeType: [.func, .property, .line, .enumCase])
        let shufflePlugin = FileShuffleHandlePlugin(order: true)
        let processingManager = ProcessingManager(path: filePath, fileHandlePlugins: [prefixPlugin, shufflePlugin])
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

