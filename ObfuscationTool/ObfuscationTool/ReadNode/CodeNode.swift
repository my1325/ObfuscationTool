//
//  CodeNode.swift
//  ObfuscationTool
//
//  Created by zzy on 2023/8/21.
//

import Foundation
import ProcessingFiles

enum NodeType {
    case propertyType
    case classType
    case protocolType
    case blockType
    case funcType
    case fileType
}
protocol BaseNodeProtocol {
    func getString(addRubbish:Bool) -> String
    var nodeType:NodeType {get}
}
extension BaseNodeProtocol {
     func getString(addRubbish:Bool) -> String {
        return ""
    }
    var nodeType: NodeType {
        return .blockType
    }
}

class BaseNode:BaseNodeProtocol {
     func getString(addRubbish:Bool) -> String {
        return ""
    }
    lazy var replaceStr:String = {
        getRandomStr()
    }()
}

extension Array:BaseNodeProtocol where Element:BaseNodeProtocol {
    func getString(addRubbish:Bool) -> String {
        var str:String = ""
        var allNode:[Element] = self
        while allNode.count > 0 {
            let index = Int(arc4random()) % allNode.count
            str.append(allNode[index].getString(addRubbish:addRubbish))
//            str.append("\n")
            allNode.remove(at: index)
        }
        return str
    }
    
    func getRandomIndex() -> Int {
        if self.count > 0 {
            return Int(arc4random()) % self.count
        }
        return 0
    }
}

class FunctionBlockNode: BaseNode {
    override func getString(addRubbish:Bool) -> String {
        var str:String = ""
        str.append(extStrs.joined())
        if str.ignoreEmpty().count > 0 {
            str.append("\n")
        }
        str.append(code)
        if str.ignoreEmpty().count > 0 {
            str.append("\n")
        }
        return str
    }
    //前项
    var extStrs:[String]
    var code:String
    init(extStrs:[String], code: String) {
        self.extStrs = extStrs
        self.code = code
    }
    var nodeType: NodeType {
        return .blockType
    }
}


func getRandomStr() -> String {
    var charts:[Character] = []
    let startChar:Int = Int(65 + arc4random() % 26)
    let chartCount = 5 + arc4random() % 8
    charts.append(Character(UnicodeScalar(startChar) ?? "s"))
    for _ in 0 ..< chartCount {
        let result:Int = Int(97 + arc4random() % 26)
        charts.append(Character(UnicodeScalar(result) ?? "s"))
    }
    let result = String(charts)
    return result
}

//属性
class ArgumentNode:BaseNode {
     override func getString(addRubbish:Bool) -> String {
        var str:String = ""
        str.append(extStrs.joined())
         if str.ignoreEmpty().count > 0 {
             str.append("\n")
         }
        str.append(code)
        if str.ignoreEmpty().count > 0 {
            str.append("\n")
        }
        return str
    }
    var nodeType: NodeType {
        return .propertyType
    }
    
    //前项
    var extStrs:[String]
    var name: String
    var code: String
    init(extStrs:[String], name: String, code: String) {
        self.extStrs = extStrs
        self.name = name
        self.code = code
    }
}

//方法 内部方法可以打乱,其他顺序不能乱
class FunctionNode:BaseNode {
     override func getString(addRubbish:Bool) -> String {
        var str:String = ""
        str.append(extStrs.joined())
         if str.ignoreEmpty().count > 0 {
             str.append("\n")
         }
        str.append(functionFirstLine)
        str.append("\n")
        str.append(blockCode.map({$0.getString(addRubbish:addRubbish)}).joined())
        var allNode:[BaseNode] = []
        allNode.append(contentsOf: subFunctionNodes)
        allNode.append(contentsOf: subClasss)
        str.append(allNode.getString(addRubbish:addRubbish))
        str.append(blockEndStr)
        str.append("\n")
        return str
    }
    var nodeType: NodeType {
        return .funcType
    }
    //前项
    var extStrs:[String]
    
    //代码
    var code:String
    
    var functionFirstLine:String
    //"}"
    var blockEndStr:String
    
    var preNode:BaseNode?
    //方法
    var subFunctionNodes:[BaseNode]
    //方法名
    var functionName:String
    //方法参数 有问题
    var argmentsName:[String]
    //子类
    var subClasss:[BaseNode]
    
    // 方法局部变量 顺序不能乱
//    var argments:[ArgumentNode]
    //逻辑代码块,顺序不能乱
    var blockCode:[FunctionBlockNode]
    
    
    
    init(extStrs:[String], code: String, functionFirstLine:String, blockEndStr:String, preNode: FunctionNode? = nil, subFunctionNodes: [FunctionNode], functionName: String, argmentsName: [String], subClasss: [ClassNode], blockCode:[FunctionBlockNode]) {
        self.code = code
        self.functionFirstLine = functionFirstLine
        self.blockEndStr = blockEndStr
        self.extStrs = extStrs
        self.preNode = preNode
        self.subFunctionNodes = subFunctionNodes
        self.functionName = functionName
        self.argmentsName = argmentsName
        self.subClasss = subClasss
        self.blockCode = blockCode
    }
}

// 类
class ClassNode:BaseNode {
    var nodeType: NodeType {
        return .classType
    }
    // struct不能换位置
     override func getString(addRubbish:Bool) -> String {
        var str:String = ""
        str.append(extStrs.joined())
         if str.ignoreEmpty().count > 0 {
             str.append("\n")
         }
        str.append(classFirstLine)
        str.append("\n")
        var allNode:[BaseNode] = []
        if self.type.contains("struct") {
            str.append(blockCode.map({$0.getString(addRubbish:addRubbish)}).joined())
        } else {
            allNode.append(contentsOf: blockCode)
        }
         
         var functionNodes = self.subFunctionNodes
         if addRubbish, let node = RubbishService.shared.getRandomFuncCode() {
             functionNodes.insert(node, at: functionNodes.getRandomIndex())
         }
        allNode.append(contentsOf: functionNodes)
        allNode.append(contentsOf: subClass)
        
        allNode.append(contentsOf: argmentsName)
        str.append(allNode.getString(addRubbish:addRubbish))
        str.append(blockEndStr)
        str.append("\n")
        return str
    }
    //类型
    var type:String
    //前项
    var extStrs:[String]
    //类名
    var className:String
    //代码
    var code:String
    var classFirstLine:String
    //"}"
    var blockEndStr:String
    //方法
    var subFunctionNodes:[BaseNode]
    //子类
    var subClass:[BaseNode]
    //属性 顺序可乱
    var argmentsName:[BaseNode]
    var blockCode:[FunctionBlockNode]

    init(type:String, extStrs: [String], className: String, code: String, classFirstLine: String, blockEndStr: String, subFunctionNodes: [BaseNode], subClass: [BaseNode], argmentsName: [BaseNode], blockCode: [FunctionBlockNode]) {
        self.type = type
        self.extStrs = extStrs
        self.className = className
        self.code = code
        self.classFirstLine = classFirstLine
        self.blockEndStr = blockEndStr
        self.subFunctionNodes = subFunctionNodes
        self.subClass = subClass
        self.argmentsName = argmentsName
        self.blockCode = blockCode
    }
}

class ExtensionNode:BaseNode {
    var nodeType: NodeType {
        return .protocolType
    }
     override func getString(addRubbish:Bool) -> String {
        var str:String = ""
        str.append(extStrs.joined())
         if str.ignoreEmpty().count > 0 {
             str.append("\n")
         }
        str.append(classFirstLine)
        str.append("\n")
        var allNode:[BaseNode] = []
        var functionNodes = self.subFunctionNodes
        if addRubbish, let node = RubbishService.shared.getRandomFuncCode() {
            functionNodes.insert(node, at: functionNodes.getRandomIndex())
        }
        allNode.append(contentsOf: functionNodes)
        allNode.append(contentsOf: subClass)
        allNode.append(contentsOf: blockCode)
        str.append(allNode.getString(addRubbish:addRubbish))
        str.append(blockEndStr)
        str.append("\n")
        return str
    }
    //前项
    var extStrs:[String]
    //代码
    var code:String
    var classFirstLine:String
    //"}"
    var blockEndStr:String
    //方法
    var subFunctionNodes:[BaseNode]
    //子类
    var subClass:[BaseNode]
    
    var blockCode:[BaseNode]
    init(extStrs: [String], code: String, classFirstLine: String, blockEndStr: String, subFunctionNodes: [BaseNode], subClass: [BaseNode], blockCode: [BaseNode]) {
        self.extStrs = extStrs
        self.code = code
        self.classFirstLine = classFirstLine
        self.blockEndStr = blockEndStr
        self.subFunctionNodes = subFunctionNodes
        self.subClass = subClass
        self.blockCode = blockCode
    }
}

// 文件
class FileNode:BaseNode {
    var nodeType: NodeType {
        return .fileType
    }
     override func getString(addRubbish:Bool) -> String {
        var str:String = ""
        var allNode:[BaseNode] = []
         var subClassNodes = self.classNodes
         if addRubbish, let node = RubbishService.shared.getRandmClassCode() {
             subClassNodes.insert(node, at: subClassNodes.getRandomIndex())
         }
        allNode.append(contentsOf: subBlock)
        allNode.append(contentsOf: funcNodes)
        allNode.append(contentsOf: subClassNodes)
        allNode.append(contentsOf: arguments)
        allNode.append(contentsOf: extensionNodes)
        str.append(allNode.getString(addRubbish:addRubbish))
        return str
    }
    var filePath:String
    var code:String
    //代码块
    var subBlock:[FunctionBlockNode]
    //方法
    var funcNodes:[FunctionNode]
    //类
    var classNodes:[ClassNode]
    //变量
    var arguments:[ArgumentNode]
    // 扩展
    var extensionNodes:[ExtensionNode]

    init(filePath:String, code: String, subBlock: [FunctionBlockNode], funcNodes: [FunctionNode], classNodes: [ClassNode], arguments: [ArgumentNode], extensionNodes: [ExtensionNode]) {
        self.filePath = filePath
        self.code = code
        self.subBlock = subBlock
        self.funcNodes = funcNodes
        self.classNodes = classNodes
        self.arguments = arguments
        self.extensionNodes = extensionNodes
    }
}

