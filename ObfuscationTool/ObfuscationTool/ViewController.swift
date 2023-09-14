//
//  ViewController.swift
//  ObfuscationTool
//
//  Created by mayong on 2023/8/18.
//

import Cocoa
import ProcessingFiles
//sudo chmod -R 755 文件目录

class ViewController: NSViewController {
    @IBOutlet weak var filePathTextFiled: NSScrollView!
    
    @IBOutlet weak var preStrTextFiled: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
//        (self.filePathTextFiled.documentView as? NSTextView)?.string = ""
//        let files = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)[0].appending("/MOXiiWhitePointerService.swift")
//        let nodes = ReadNode.getNodes(filePath: files)
        RubbishService.shared.loadData()
        debugPrint("")
    }
    @IBAction func clickReplaceClass(_ sender: Any) {
        let preStr = preStrTextFiled.stringValue.uppercased().ignoreEmpty().replacingOccurrences(of: "\n", with: "")
        guard let textView = filePathTextFiled.documentView as? NSTextView else {
            return
        }
        let filePaths = textView.string.components(separatedBy: "\n")
        guard filePaths.count > 0 else {
            return
        }
        for filePath in filePaths {
            if FileManager.default.fileExists(atPath: filePath) == false {
                return
            }
        }
//       let indictor = NSProgressIndicator()
//        indictor.frame = CGRect(origin: CGPoint(x: ((NSScreen.main?.frame.width ?? 0) - 80) / 2.0, y: ((NSScreen.main?.frame.height ?? 0) - 80) / 2.0), size: CGSize(width: 80, height: 80))
//        self.view.addSubview(indictor)
//        indictor.animator()
        ReadNode.replaceClaseName(filePathStrs: filePaths, preStr: preStr)
    }
    
    @IBAction func clickExchang(_ sender: NSButton) {
        guard let textView = filePathTextFiled.documentView as? NSTextView else {
            return
        }
        let filePaths = textView.string.components(separatedBy: "\n")
        guard filePaths.count > 0 else {
            return
        }
        for filePath in filePaths {
            if FileManager.default.fileExists(atPath: filePath) == false {
                return
            }
        }
        ReadNode.exchageLineFileNodes(filePathStrs: filePaths)
    }
}

