//
//  ViewController.swift
//  ObfuscationTool
//
//  Created by mayong on 2023/8/18.
//

import Cocoa
import ProcessingFiles

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        let panel = NSOpenPanel()
//        panel.canChooseDirectories = true
//        panel.canChooseFiles = false
//        panel.begin(completionHandler: { response in
//            response
//        })
        // Do any additional setup after loading the view.
//        let file = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)[0]
        let home: String
        // home 路径(第一种)
//        if let pw = getpwuid(getuid()), var pw_dir = pw.pointee.pw_dir {
//            home = String(cString: pw_dir)
//            print(home)
//        } else {
//            home = ""
//        }
        // home路径（第二种）
        let homeDirectory = NSHomeDirectory()
        let homeComponents = homeDirectory.components(separatedBy: "/")
        home = Array(homeComponents[0 ..< 3]).joined(separator: "/")
        let file = String(format: "%@/Desktop/Tools", home)
        print(file)
        print(FileManager.default.fileExists(atPath: file))
        print(FileManager.default.createFile(atPath: String(format: "%@/text", file), contents: nil))
        do {
            try FileManager.default.createDirectory(atPath: String(format: "%@/dir", file), withIntermediateDirectories: true)
        } catch {
            print(error)
        }
//        print(url.startAccessingSecurityScopedResource())
//        FileManager.default
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

