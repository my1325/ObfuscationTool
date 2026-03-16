//
//  ViewController.swift
//  ObfuscationTool
//
//  Created by mayong on 2023/8/18.
//

import Cocoa
//import ProcessingFiles
//sudo chmod -R 755 文件目录

class ViewController: NSViewController {
    @IBOutlet weak var filePathTextFiled: NSScrollView!
    
    @IBOutlet weak var desPathTextFiled: NSScrollView!
    
    @IBOutlet weak var repleaseTextFiled: NSTextField!
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
        print("替换完成")
    }
    
    @IBAction func clickMoveFile(_ sender: Any) {
        guard let preTextView = filePathTextFiled.documentView as? NSTextView else {
            return
        }
        guard let desTextView = desPathTextFiled.documentView as? NSTextView else {
            return
        }
        let filePaths = preTextView.string.components(separatedBy: "\n")

        let desfilePaths = desTextView.string.components(separatedBy: "\n").first ?? ""

        for filePath in filePaths {
            if FileManager.default.fileExists(atPath: filePath) == false {
                return
            }
            AssetsNode.movePath(file: filePath, desPath: desfilePaths)
        }
    }
    @IBAction func clickAssets(_ sender: Any) {
        let preStr = preStrTextFiled.stringValue.ignoreEmpty().replacingOccurrences(of: "\n", with: "")
        let pleaseStr = repleaseTextFiled.stringValue.ignoreEmpty().replacingOccurrences(of: "\n", with: "")
        
        guard let textView = filePathTextFiled.documentView as? NSTextView else {
            return
        }
        let filePaths = textView.string.components(separatedBy: "\n")
        for filePath in filePaths {
            if FileManager.default.fileExists(atPath: filePath) == false {
                return
            }
            AssetsNode.changeAssetFile(file: filePath, str: preStr, pleaseStr: pleaseStr)
        }
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
        print("操作完成")
    }
    @IBAction func clickRecreate(_ sender: Any) {
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
        ReadNode.create_newFile(filePaths: filePaths)
    }
}

