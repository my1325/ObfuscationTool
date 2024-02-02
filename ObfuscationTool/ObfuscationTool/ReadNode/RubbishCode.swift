//
//  RubishCode.swift
//  
//
//  Created by zzy on 2023/9/13.
//

import Cocoa

func rubbishFunc() -> Bool {
    var result = 1
    var result1: Int = Int(arc4random())
    
    result += result1
    if result > 10 {
        result = 1
    }
    
    return result > 2
}

enum TestCode {
    case propertyType
    case classType
    case protocolType
    case blockType
    case funcType
    case fileType
}


struct TestCodeStr {
    var preStr:String
    var nextStr:String
    var bodyStr:String
    var lastStr:String
    var firs:Int
    var index:Int
    var nameStr:String
    var nickName:String
    var clashStr:String
    
    func nextResult() -> Bool {
        if self.index < 1 {
            return false
        }
        return true
    }
}