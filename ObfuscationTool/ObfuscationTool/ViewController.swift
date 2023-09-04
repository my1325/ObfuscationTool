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
    @IBAction func clickReplaceClass(_ sender: Any) {
        let preStr = preStrTextFiled.stringValue.uppercased().ignoreEmpty().replacingOccurrences(of: "\n", with: "")
        let filePath = ""//filePathTextFiled.string
        guard filePath.count > 0 else {
            return
        }
        if FileManager.default.fileExists(atPath: filePath) == false {
            return
        }
        ReadNode.replaceClaseName(filePathStr: filePath, preStr: preStr)
    }
    @IBAction func clickExchang(_ sender: NSButton) {
        guard let textView = filePathTextFiled.documentView as? NSTextView else {
            return
        }
        let filePath = textView.string
        guard filePath.count > 0 else {
            return
        }
        if FileManager.default.fileExists(atPath: filePath) == false {
            return
        }
        ReadNode.exchageLineFileNodes(filePathStr: filePath)
    }
}

