//
//  ViewController.swift
//  ObfuscationTool
//
//  Created by mayong on 2023/8/18.
//

import Cocoa
// import SnapKit
import Combine
import FilePath
import Plugins
import ProcessingFiles
import SwiftFilePlugin

class ViewController: NSViewController {
//    private lazy var segmentedControl: SegmentedControl = {
//        $0.translatesAutoresizingMaskIntoConstraints = false
//        $0.items = ["Confusion", "Crypt"]
//        self.view.addSubview($0)
//        $0.snp.makeConstraints { make in
//            make.top.leading.trailing.equalTo(0)
//            make.height.equalTo(40)
//        }
//        return $0
//    }(SegmentedControl(frame: .zero))

    var sinkStore: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()

//        segmentedControl.$selectedIndex.sink(receiveValue: {
//            print($0)
//        }).store(in: &sinkStore)
        
        testProcessingFile()
    }

    func testProcessingFile() {
        guard let filePath = Path.instanceOfPath("") else { return }
        let prefixPlugin = FileStringHandlePlugin([.prefix(mode: .addOrReplace, prefix: "ot", separator: "_")], codeType: [.func, .property, .line, .enumCase])
        let shufflePlugin = FileShuffleHandlePlugin(order: true)
        let processingManager = ProcessingManager(path: filePath)
        processingManager.registerPlugin(SwiftFileProcessingPlugin(plugins: [shufflePlugin]), forFileType: .fSwift)
        do {
            let files = try processingManager.processing()
            for file in files {
                do {
                    if let data = try file.getContent().data(using: .utf8) {
                        try file.filePath.writeData(data)
                    }
                } catch {
                    print(error)
                }
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
