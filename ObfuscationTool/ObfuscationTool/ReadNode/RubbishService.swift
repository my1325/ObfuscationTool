//
//  RubbishService.swift
//  ObfuscationTool
//
//  Created by zzy on 2023/9/13.
//

import Cocoa
import Foundation

class RubbishService: NSObject {
    static let shared:RubbishService = RubbishService()
    var fileNode:FileNode?

    func loadData() {
        if let path = Bundle.main.path(forResource: "Rubbish", ofType: "txt") {
            let fileNode = ReadNode.getFileNode(filePathStr: path)
            self.fileNode = fileNode
        }
    }
    
    func getRandomFuncCode() -> FunctionNode? {
        if let functionNodes = self.fileNode?.funcNodes, functionNodes.count > 0 {
            let randomIndex:Int = Int(arc4random()) % functionNodes.count
            let node = functionNodes[randomIndex]
            let name = getRandomStr()
            let functionName = getRandomStr()
            let replaceCode = node.code.replacingOccurrences(of: "result", with: name).replacingOccurrences(of: node.functionName, with: functionName)
            
            return ReadNode.getFunction(extStrs: node.extStrs, functionStr: replaceCode)
        }
        return nil;
    }
    
    func getRandmClassCode() -> ClassNode? {
        if let functionNodes = self.fileNode?.classNodes, functionNodes.count > 0 {
            let randomIndex:Int = Int(arc4random()) % functionNodes.count
            let node = functionNodes[randomIndex]
            let className = getRandomStr()
            let replaceCode = node.code.replacingOccurrences(of: node.className, with: className)
            
            return ReadNode.getClassNodeStr(extStrs: node.extStrs, classarm: node.type, classContent: replaceCode)
        }
        return nil;
    }
    
}
