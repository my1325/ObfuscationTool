//
//  ViewController.swift
//  ObfuscationTool
//
//  Created by mayong on 2023/8/18.
//

import Cocoa
//import ProcessingFiles
import SwiftString

class BaseViewController: NSViewController {
    class var abc: Int { 1 }
}

class ViewController: BaseViewController {

    override class var abc: Int
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let string = SwiftString(string: "hello world hello world hello worldhello world hello world")
        do {
            let replaceString = try string.replaceWithMatches("wor", with: "aaa")
            print(replaceString.string)
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

