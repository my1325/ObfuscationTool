//
//  ReadNode.swift
//  ObfuscationTool
//
//  Created by zzy on 2023/8/21.
//

import Foundation
import FilePath

//@相关
let aiteNames:[String] = []

//系统方法
let systemFunctions:[String] = []

//语法左边
let leftPropertyCodes:[String] = ["{","(","<","\""]

//语法右边
let rightPropertyCodes:[String] = ["}",")",">","\""]

let classNames:[String] = ["protocol ", "enum ", "class ", "struct "]



let propertyNames:[String] = [" var ", " let "]
let funcTargets:[String] = ["func ", "init(", "deinit"]

var replacePreStr:String = "FDSKDFJSDFSJKDFJKSFDLA_"


//1,删除注释
//2,拆分
//3,生成替换代码
//4,替换

//重名的方法


class test3<T>: NSObject {
    
}

extension String {
    func ignoreEmpty() -> String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    func countChar(startStr:String, endStr:String) -> Int {
        var resultCount = 0
        let ignorStr = self.ignoreEmpty().replacingOccurrences(of: "\n", with: "")
        if startStr == "#if" {
            if ignorStr.hasPrefix(startStr) {
                resultCount += 1
            }
            if ignorStr.hasSuffix(endStr) {
                resultCount -= 1
            }
        } else {
            let starChar = Character(startStr)
            let endChar = Character(endStr)
            for char in self {
                if char == starChar {
                    resultCount += 1
                }
                if char == endChar {
                    resultCount -= 1
                }
            }
        }
        
        return resultCount
    }
    
    func fileterEndCode() -> String {
        let reverseCode = String(self.reversed())
        var count:Int = 0
        for subCode in reverseCode {
            count += 1
            if subCode == "}" {
                break
            }
        }
        var reverseStr = reverseCode as NSString
        reverseStr = reverseStr.substring(from: count) as NSString
        let newFunctionStr = String((reverseStr as String).reversed())
        return newFunctionStr
    }
    
    
}

class CharsData {
    var startStr:String
    var endStr:String
    var charCount:Int
    init(startStr: String, endStr: String, charCount: Int) {
        self.startStr = startStr
        self.endStr = endStr
        self.charCount = charCount
    }
}

struct CLassReplace {
    var originStr:String
    var replaceStr:String
    init(originStr: String, replaceStr: String) {
        self.originStr = originStr
        self.replaceStr = replaceStr
    }
}


let customDirectorPath:String = ""



class CacheData {
    static let shared:CacheData = CacheData()
    var data:[Int:String] = [:]
}

class ReadNode {
    private class func getBlockCode(lineStr:String, lines:[String], superType:NodeType, currentType:NodeType) -> (String,Int) {
        var needBlockContent:Bool
        if superType == .propertyType {
            needBlockContent = false
        } else {
            switch currentType {
            case .protocolType:
                needBlockContent = false
            case .propertyType:
                needBlockContent = false
            case .classType:
                needBlockContent = true
            case .blockType:
                needBlockContent = false
            case .funcType:
                needBlockContent = true
            case .fileType:
                needBlockContent = false
            }
        }

        let afterNeedsContinueStrs:[String] = ["=","(","{","->","where", ":", ",", "+", "."]
        let nextNeedsContinueStrs:[String] = ["=","->","where","+"]
        let cacheLines = lines
        let itemChars:[CharsData] = [CharsData(startStr: "{", endStr: "}", charCount: 0), CharsData(startStr: "(", endStr: ")", charCount: 0), CharsData(startStr: "#if", endStr: "#endif", charCount: 0),CharsData(startStr: "[", endStr: "]", charCount: 0)]
        let blockChar:CharsData = CharsData(startStr: "{", endStr: "}", charCount: 0)
        var startBegain:Bool = false
        var startVerify:Bool = false
        var totalCount = 0
        var codeStr:String = ""
        for i in 0 ..< cacheLines.count {
            let item = cacheLines[i]
            if lineStr == item {
                startBegain = true
            }
            if startBegain {
                for itemChar in itemChars {
                    itemChar.charCount += item.countChar(startStr: itemChar.startStr, endStr: itemChar.endStr)
                }
                codeStr.append(item)
                codeStr.append("\n")
                totalCount += 1
                
                if needBlockContent {
                    if !startVerify {
                        let itemStr = item as NSString
                        if itemStr.contains(blockChar.startStr) {
                            startVerify = true
                        }
                    }
                } else {
                    startVerify = true
                }

                if startVerify {
                    if itemChars.map({$0.charCount}).reduce(0, {$0+$1}) == 0 {
                        var continueBool = false
                        let newItemStr = item.ignoreEmpty()
                        for neesContinueStr in nextNeedsContinueStrs {
                            if newItemStr.hasSuffix(neesContinueStr) {
                                continueBool = true
                                break
                            }
                        }
                        if continueBool {
                            continue
                        }
                        if i < cacheLines.count - 1 {
                            let nextLineStr = cacheLines[i + 1].ignoreEmpty()
                            
                            for neesContinueStr in afterNeedsContinueStrs {
                                if nextLineStr.hasPrefix(neesContinueStr) {
                                    continueBool = true
                                    break
                                }
                            }
                            if continueBool {
                                continue
                            }
                        }
//                        codeStr.removeLast()
                        break
                    }
                }
            }
        }
        return (codeStr, totalCount)
    }
    
    
    private class func getFunctionName(lines:[String]) -> (String, Int) {
        var codeStr:String = ""
        
        var startVerify:Bool = false
        let items = lines
        var totalCount = 0
        let itemChars:[CharsData] = [CharsData(startStr: "(", endStr: ")", charCount: 0)]
        
        for item in items {
            if !startVerify {
                let itemStr = item as NSString
                for itemChar in itemChars {
                    if itemStr.contains(itemChar.startStr) {
                        startVerify = true
                        break
                    }
                }
            }
            for itemChar in itemChars {
                itemChar.charCount += item.countChar(startStr: itemChar.startStr, endStr: itemChar.endStr)
            }
            codeStr.append(item)
            codeStr.append("\n")
            totalCount += 1
            if startVerify {
                if itemChars.map({$0.charCount}).reduce(0, {$0+$1}) == 0 {
                    codeStr.removeLast()
                    break
                }
            }
        }
        
        return (codeStr, totalCount)
    }
    
    
    private class func getPropertyCode(extStrs:[String], armStr:String, contentStr:String) -> ArgumentNode {
        let items:[String] = contentStr.components(separatedBy: "\n")
        var name:String = ""
        if let firstItem = items.first {
            let str = firstItem as NSString
            let startRange = str.range(of: armStr)
            let endRange:NSRange
            if str.contains(":") {
                endRange = str.range(of: ":")
            } else {
                endRange = str.range(of: "=")
            }
            if startRange.location < 0 || endRange.location < 0  || startRange.location > 1000 || endRange.location > 1000{
                assert(false)
            }
            let start = startRange.location + startRange.length
            let length = endRange.location - start
            if str.length < start + length  || length < 0{
                assert(false)
            }
            
            name = str.substring(with: NSRange(location: start, length: length)).ignoreEmpty()
        }
        
        return ArgumentNode(extStrs: extStrs, name: name, code: contentStr)
    }
    
    
    
    private class func getClassName(lines:[String]) -> (String, Int) {
        var cacheLines = lines
        var codeStr:String = ""
        var count:Int = 0
        while cacheLines.count > 0 {
            let firstLine = cacheLines.removeFirst()
            codeStr.append(firstLine)
            codeStr.append("\n")
            count += 1
            if firstLine.ignoreEmpty().last == "{" {
                break
            }
        }
        
        return (codeStr, count)
    }
    
    class func getClassNodeStr(extStrs:[String], classarm:String, classContent: String) -> ClassNode {
        let dealWithResult = classContent.fileterEndCode()
        var classLineItems:[String] = dealWithResult.components(separatedBy: "\n")
        let firsLine = getClassName(lines: classLineItems)
        var firstLineStr = firsLine.0
        classLineItems.removeSubrange(0 ..< firsLine.1)
        
        
        
        if let nextLine = classLineItems.first {
            if nextLine.ignoreEmpty().hasPrefix("{") == true {
                var nextLineStr = nextLine as NSString
                let firstIndex = nextLineStr.range(of: "{")
                nextLineStr = nextLineStr.replacingCharacters(in: firstIndex, with: "") as NSString
                classLineItems[0] = nextLineStr as String
                firstLineStr.append(" {")
            }
        }
        
        var className:String = ""
        let classLine = firstLineStr
        let newLine = classLine as NSString
        
        let endRange1 = newLine.range(of: "{")
        let endRange2 = newLine.range(of: ":")
        let endRange3 = newLine.range(of: "<")
        let endRange = [endRange1, endRange2, endRange3].filter({$0.length > 0}).sorted(by: {$0.location < $1.location}).first ?? NSRange(location: newLine.length, length: 0)
        let startRange = newLine.range(of: classarm)
        
        let start = startRange.location + startRange.length
        let length = endRange.location - start
        if newLine.length < start + length  || length < 0{
            assert(false)
        }
        
        className = newLine.substring(with: NSRange(location: start, length: length)).ignoreEmpty().replacingOccurrences(of: "\n", with: "")
        var nodeType:NodeType = .classType
        switch classarm {
        case "protocol ":
            nodeType = .propertyType
        default: break
        }
        
        let partCode = getPartCode(allLines: classLineItems, contentStr: classContent, nodeType:nodeType)
        let subFunctionNodes:[FunctionNode] = partCode.1
        let subClassNodes:[ClassNode] = partCode.0
        let subPorpertyNodes:[ArgumentNode] = partCode.2
        
        var endStr = "}"
        for first in firstLineStr {
            if first != " " {
                break
            } else {
                endStr.insert(" ", at: endStr.index(endStr.startIndex, offsetBy: 0))
            }
        }
        
        return ClassNode(type:classarm, extStrs: extStrs, className: className, code: classContent, classFirstLine: classLine, blockEndStr: endStr, subFunctionNodes: subFunctionNodes, subClass: subClassNodes, argmentsName: subPorpertyNodes, blockCode: partCode.3)
    }
    
    
    private class func getExtensionNodeStr(extStrs:[String], classContent: String) -> ExtensionNode {
        let dealWithResult = classContent.fileterEndCode()
        var classLineItems:[String] = dealWithResult.components(separatedBy: "\n")
        let firsLine = getClassName(lines: classLineItems)
        var firstLineStr = firsLine.0
        classLineItems.removeSubrange(0 ..< firsLine.1)
//        var firstLineStr = classLineItems.removeFirst()
        
        if let nextLine = classLineItems.first {
            if nextLine.ignoreEmpty().hasPrefix("{") == true {
                var nextLineStr = nextLine as NSString
                let firstIndex = nextLineStr.range(of: "{")
                nextLineStr = nextLineStr.replacingCharacters(in: firstIndex, with: "") as NSString
                classLineItems[0] = nextLineStr as String
                firstLineStr.append(" {")
            }
        }
        
        let partCode = getPartCode(allLines: classLineItems, contentStr: classContent, nodeType:.classType)
        let subFunctionNodes:[FunctionNode] = partCode.1
        let subClassNodes:[ClassNode] = partCode.0
        
        var endStr = "}"
        for first in firstLineStr {
            if first != " " {
                break
            } else {
                endStr.insert(" ", at: endStr.index(endStr.startIndex, offsetBy: 0))
            }
        }
        return ExtensionNode(extStrs: extStrs, code: classContent, classFirstLine: firstLineStr, blockEndStr: endStr, subFunctionNodes: subFunctionNodes, subClass: subClassNodes, blockCode: partCode.3)
    }
    
    class func getFunction(extStrs:[String], functionStr:String) -> FunctionNode {
        let dealWithResult = functionStr.fileterEndCode()
        if dealWithResult.count > 0 {
            var functionLineItems:[String] = dealWithResult.components(separatedBy: "\n")
            func argumentCodeStrWith(str:String, startChar:String) -> String {
                let newStr = (str as NSString)
                let endRange = newStr.range(of: startChar)
                
                var dealStr = newStr.substring(to: endRange.location)
                
                if dealStr.first == "_" {
                    dealStr.removeFirst()
                }
                
                return dealStr.ignoreEmpty()
            }
            
            func funcNameCodeStrWith(str :NSString) -> String {
                var resutStr:String = ""
                
                let newStr = str
                
                let startRange = newStr.range(of: "func ")
                if startRange.length == 0 {
                    let string = newStr as String
                    
                    if string.ignoreEmpty().contains("init(")  {
                        return "init"
                    } else if string.ignoreEmpty().hasPrefix("deinit") {
                        return "deinit"
                    }
                }
                
                let endRange1 = newStr.range(of: "<")
                let endRange2 = newStr.range(of: "(")
                var endRange:NSRange = endRange2
                if endRange1.location < endRange2.location {
                    if endRange1.length > 0 {
                        endRange = endRange1
                    }
                }
                
                let start = startRange.location + startRange.length
                let length = endRange.location - start
                if newStr.length < start + length || length < 0{
                    assert(false)
                }
                resutStr = newStr.substring(with: NSRange(location: start, length: length))
                
                return resutStr.ignoreEmpty()
            }
            
            let result = getFunctionName(lines: functionLineItems)
            functionLineItems.removeSubrange(0 ..< result.1)
            var firstItem = result.0
            
    //            let firstItem = functionLineItems.removeFirst() as NSString
            if let nextLine = functionLineItems.first {
                if nextLine.ignoreEmpty().hasPrefix("{") == true {
                    var nextLineStr = nextLine as NSString
                    let firstIndex = nextLineStr.range(of: "{")
                    nextLineStr = nextLineStr.replacingCharacters(in: firstIndex, with: "") as NSString
                    functionLineItems[0] = nextLineStr as String
                    firstItem.append(" {")
                }
            }
            
            let functionName:String = funcNameCodeStrWith(str: firstItem as NSString)
            
            var argumentItems:[String] = []
    //            var argumentStr = ""
    //            let startRange = firstItem.range(of: "(")
    //            let endRange = firstItem.range(of: ")")
            //    func test1(hshsh:[String] = ["sjdjkj",
    //            "sjdsjkds",
    //            "sdkldskjdsk"]) {
    //
    //            } 不能分割开
    //            argumentStr = firstItem.substring(with: NSRange(location: startRange.location + startRange.length, length: endRange.location - startRange.location - startRange.length))
    //            if argumentStr.count > 0 {
    //                let arguments = argumentStr.components(separatedBy: ",")
    //                for argument in arguments {
    //                    let argumentItem = argumentCodeStrWith(str: argument, startChar: ":")
    //                    argumentItems.append(argumentItem)
    //                }
    //            }
            let partCode = getPartCode(allLines: functionLineItems, contentStr: functionStr, nodeType:.funcType)
            let subFunctionNodes:[FunctionNode] = partCode.1
            let subClassNodes:[ClassNode] = partCode.0
            let subPorpertyNodes:[FunctionBlockNode] = partCode.3
            var endStr = "}"
            for first in firstItem {
                if first != " " {
                    break
                } else {
                    endStr.insert(" ", at: endStr.index(endStr.startIndex, offsetBy: 0))
                }
            }
            return FunctionNode(extStrs: extStrs, code: functionStr, functionFirstLine: firstItem as String, blockEndStr: endStr, preNode: nil, subFunctionNodes: subFunctionNodes,functionName: functionName, argmentsName: argumentItems, subClasss: subClassNodes, blockCode: subPorpertyNodes)
        } else {
            return FunctionNode(extStrs: extStrs, code: functionStr, functionFirstLine: functionStr, blockEndStr: "", subFunctionNodes: [], functionName: "", argmentsName: [], subClasss: [], blockCode: [])
        }
    }
    
    private class func getPartCode(allLines:[String], contentStr:String, nodeType:NodeType) -> ([ClassNode],[FunctionNode],[ArgumentNode],[FunctionBlockNode], [ExtensionNode]) {
        var functionLineItems = allLines
        
        var subFunctionNodes:[FunctionNode] = []
        var subClassNodes:[ClassNode] = []
        var subPorpertyNodes:[ArgumentNode] = []
        var subLines:[FunctionBlockNode] = []
        var extensions:[ExtensionNode] = []
        var extrTexts:[String] = []
        while functionLineItems.count > 0 {
            let currentLine = functionLineItems.first ?? ""
            if currentLine == "public protocol DIMOSegmentedViewRTLCompatible: class {" {
                print("slds;lsdl")
            }
            if currentLine == "" {
                functionLineItems.removeFirst()
                continue
            }
            var found:Bool = false
//            let funcTargets:[String] = ["func ", "init(", "deinit"]
            let ignoreLine = currentLine.ignoreEmpty()
            if currentLine.contains("func ") {
                found = true
            }
            
            if !found {
                if currentLine.contains("init(") {
                    let ignoreLine = currentLine.ignoreEmpty()
                    if !(ignoreLine.hasPrefix("super.") || ignoreLine.hasPrefix("self.") || ignoreLine.contains(".init(")) {
                        found = true
                    }
                }
            }
            if !found {
                if ignoreLine.hasPrefix("deinit") {
                    found = true
                }
            }
            
            
            if found {
                let (subfuncStr, lineCount) = getBlockCode(lineStr: currentLine, lines: functionLineItems, superType: nodeType, currentType: .funcType)
                functionLineItems.removeFirst(lineCount)
                let functionNode = getFunction(extStrs:extrTexts, functionStr: subfuncStr)
                subFunctionNodes.append(functionNode)
                extrTexts.removeAll()
            } else {
                for classStr in propertyNames {
                    if currentLine.contains(classStr) {
                        found = true
                        let (subPropertyStr, lineCount) = getBlockCode(lineStr: currentLine, lines: functionLineItems, superType: nodeType, currentType: .propertyType)
                        functionLineItems.removeSubrange(0 ..< lineCount)
                        subLines.append(FunctionBlockNode(extStrs:extrTexts, code: subPropertyStr))
                        extrTexts.removeAll()
                        break
                    }

                }
                
                if !found {
                    for classStr in classNames {
                        if currentLine.contains(classStr) {
                            found = true
                            assert(functionLineItems.count != 0)
                            let (subClassStr, lineCount) = getBlockCode(lineStr: currentLine, lines: functionLineItems, superType: nodeType, currentType: .classType)
                            functionLineItems.removeSubrange(0 ..< lineCount)
                            let subClassNode = getClassNodeStr(extStrs:extrTexts, classarm:classStr,classContent: subClassStr)
                            subClassNodes.append(subClassNode)
                            extrTexts.removeAll()
                            break
                        }
                    }
                }

                
                if !found {
                    if currentLine.ignoreEmpty().hasPrefix("extension") {
                        found = true
                        let (subClassStr, lineCount) = getBlockCode(lineStr: currentLine, lines: functionLineItems, superType: nodeType, currentType: .classType)
                        functionLineItems.removeSubrange(0 ..< lineCount)
                        let subExtension = getExtensionNodeStr(extStrs: extrTexts, classContent: subClassStr)
                        extensions.append(subExtension)
                        extrTexts.removeAll()
                    }
                }
//
//                    if !found {
//                        // 如何寻找属性的代码 , =后面换行未处理
//                        for classStr in propertyNames {
//                            if currentLine.contains(classStr) {
//                                found = true
//                                let (subPropertyStr, lineCount) = getBlockCode(lineStr: currentLine, lines: functionLineItems, isPrperty: true)
//                                functionLineItems.removeSubrange(0 ..< lineCount)
//                                let property = getPropertyCode(extStrs: extrTexts, armStr: classStr, contentStr: subPropertyStr)
//                                subPorpertyNodes.append(property)
//                                extrTexts.removeAll()
//                            }
//
//                        }
//                    }
                
                if !found {
                    if currentLine.ignoreEmpty().hasPrefix("@") {
                        extrTexts.append(currentLine)
                        functionLineItems.removeFirst()
                    } else {
                        let (subPropertyStr, lineCount) = getBlockCode(lineStr: currentLine, lines: functionLineItems, superType: nodeType, currentType: .blockType)
                        functionLineItems.removeSubrange(0 ..< lineCount)
                        subLines.append(FunctionBlockNode(extStrs:extrTexts, code: subPropertyStr))
                        extrTexts.removeAll()
                    }
                }
            }
        }
        return (subClassNodes, subFunctionNodes, subPorpertyNodes, subLines, extensions)
    }
    
    private class func deleteAnnotate(currentLine:String, lines:[String]) -> (Bool,Int) {
        let newStr = currentLine.ignoreEmpty().replacingOccurrences(of: "\n", with: "") as NSString
        var found:Bool = false
        var line:Int = 0
        if newStr.hasPrefix("//") {
            found = true
            line = 1
        } else if newStr.hasPrefix("/*") {
            var begain:Bool = false
            let functionLineItems:[String] = lines
            for functionLineItem in functionLineItems {
                if functionLineItem == currentLine {
                    begain = true
                    found = true
                }
                if begain {
                    line += 1
                }
                if functionLineItem.contains("*/") {
                    if !functionLineItem.hasSuffix("*/") {
                        found = false
                    }
                    break
                }
            }
        }
        return (found, line)
    }
    
    class func getFileNode(filePathStr:String) -> FileNode {
//        let filePath = FilePath.file(file: filePathStr)
//        var fileLineItems = (try? filePath.readLines()) ?? []
//        var currentLines:[String] = []
//        fileLineItems.removeAll(where: { str in
//            let newStr = str.ignoreEmpty()
//            if newStr == "\n" || newStr == "" {
//                return true
//            }
//
//            if newStr.prefix(2) == "//" {
//                return true
//            }
//
//            return false
//        })
//        let contentStr = fileLineItems.joined(separator: "\n")
//
//        while fileLineItems.count > 0 {
//            let currentLine = fileLineItems.first ?? ""
//            let annotateResult = deleteAnnotate(currentLine: currentLine, contentStr: contentStr)
//            if annotateResult.0 {
//                fileLineItems.removeSubrange(0 ..< annotateResult.1)
//                continue
//            }
//            currentLines.append(fileLineItems.removeFirst())
//        }
//
//        let newContentStr = currentLines.joined(separator: "\n")
        if let data = try? FilePath.file(file: filePathStr).readData(), let codeStr = String(data: data, encoding: .utf8) {
            let currentLines = codeStr.components(separatedBy: "\n")
            let partCode = getPartCode(allLines: currentLines, contentStr: codeStr, nodeType: .fileType)
            let subFunctionNodes:[FunctionNode] = partCode.1
            let subClassNodes:[ClassNode] = partCode.0
            let subPorpertyNodes:[ArgumentNode] = partCode.2
            let subLines:[FunctionBlockNode] = partCode.3
            
            return FileNode(filePath:filePathStr, code:codeStr, subBlock: subLines, funcNodes: subFunctionNodes, classNodes: subClassNodes, arguments: subPorpertyNodes, extensionNodes: partCode.4)
        } else {
            assert(false)
        }
    }
    
    
    private class func getFilePath(rootDirectorPath:String) -> [String] {
        var filePaths:[String] = []
        var isDir:ObjCBool = true
        _ = FileManager.default.fileExists(atPath: rootDirectorPath, isDirectory: &isDir)
        let judgeFile:((String?) -> Bool) = { str in
//            return str == "h" || str == "m" || str == "c" || str == "mm"
            return str == "swift"
        }
        
        if !isDir.boolValue {
            let fileUrl = URL(string: rootDirectorPath)
            
            if judgeFile(fileUrl?.pathExtension) {
                filePaths.append(rootDirectorPath)
            }
            return filePaths
        }
        
        let array:[String] = (try? FileManager.default.contentsOfDirectory(atPath: rootDirectorPath)) ?? []
        for fileName in array {
            var isDir:ObjCBool = true
            let filePath:String = "\(rootDirectorPath)/\(fileName)"
            if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), let fileUrl = URL(string: filePath) {
                if !isDir.boolValue {
                    if judgeFile(fileUrl.pathExtension) {
                        filePaths.append(filePath)
                    }
                } else {
                    filePaths.append(contentsOf: getFilePath(rootDirectorPath: filePath))
                }
            }
        }
        return filePaths
    }
    
    class func getNodes(filePath:String) -> [FileNode] {
        let rootDirectorPath = filePath
        let filePaths = getFilePath(rootDirectorPath: rootDirectorPath)
        var result:[FileNode] = []
        for filePath in filePaths {
            result.append(getFileNode(filePathStr: filePath))
        }
        return result
    }
    
    private class func writeCode(fileNodes:[FileNode]) {
        for fileNode in fileNodes {
            writeStr(filePath: fileNode.filePath, str: fileNode.code)
        }
    }
    
    private class func writeStr(filePath:String, str:String) {
        let newCode:String = str
        let filePath = FilePath.file(file: filePath)
        if let data = newCode.data(using: .utf8) {
            try? filePath.writeData(data)
        }
    }
    
    //还原
    class func reductionCustomStr(filePathStr:String) {
        let filePaths = getFilePath(rootDirectorPath: filePathStr)
        for file in filePaths {
            if let data = try? FilePath.file(file: file).readData(), let codeStr = String(data: data, encoding: .utf8) {
                let regex = try? NSRegularExpression(pattern: "\(replacePreStr)[0-9]*")
                var newStr = codeStr as NSString
                var range:NSRange = NSRange(location: 0, length: 1)
                
                while range.length > 0 {
                    let match = regex?.firstMatch(in: newStr as String, range: NSRange(location: 0, length: newStr.length))
                    range = match?.range ?? NSRange(location: 0, length: 0)
                    if range.length > 0 {
                        if newStr.length < range.length  || range.length < 0{
                            assert(false)
                        }
                        let replaceStr = newStr.substring(with: range)
                        if let indexStr = replaceStr.components(separatedBy: "_").last, let index = Int(indexStr), let originStr = CacheData.shared.data[index] {
                            newStr = newStr.replacingCharacters(in: range, with: originStr) as NSString
                        }
                    }
                }
                writeStr(filePath: file, str: newStr as String)
            }
        }
    }
    //替换
    private class func replaceCustomStr(filePathStr:String) {
        let filePaths = getFilePath(rootDirectorPath: filePathStr)
        var index:Int = CacheData.shared.data.count
        
        func replaceStr(originStr:String, matchStr:String) -> String {
            let regex = try? NSRegularExpression(pattern: matchStr)
            var newStr = originStr as NSString
            var range:NSRange = NSRange(location: 0, length: 1)
            
            while range.length > 0 {
                let match = regex?.firstMatch(in: newStr as String, range: NSRange(location: 0, length: newStr.length))
                range = match?.range ?? NSRange(location: 0, length: 0)
                if range.length > 0 {
                    let str = "\(replacePreStr)\(index)"
                    if newStr.length < range.length || range.length < 0 {
                        assert(false)
                    }
                    CacheData.shared.data[index] = newStr.substring(with: range)
                    newStr = newStr.replacingCharacters(in: range, with: str) as NSString
                    index += 1
                }
            }
            return newStr as String
        }
        
        for file in filePaths {
            
            if let data = try? FilePath.file(file: file).readData(), let codeStr = String(data: data, encoding: .utf8) {
                
                var newStr = replaceStr(originStr: codeStr, matchStr: "\"\"\"(\\s|.)*?\"\"\"")
                /*
                 "\"([^\"].*)\""
                 
                 let dimo_path:String = Bundle.main.path(forResource: "DIMOEULA", ofType: "txt") ?? "" -> let dimo_path:String = Bundle.main.path(XXXXX
                 
                 
                 "\"([^\"]*)\""
                 case 34: append(staticText: "\\\"")
                 case 92: append(staticText: "\\\\")
                 ->
                 case 34: append(staticText: xxxxx xxxxx\\\\")
                 */
                
                newStr = replaceStr(originStr: newStr, matchStr: "\"([^\"].*)\"")//"\"([^\"]*)\"" 有问题
                writeStr(filePath: file, str: newStr)
                
            }
        }
    }
    // 删除注释
    private class func deletNote(filePathStr:String) {
        
        func replaceStr(originStr:String, matchStr:String) -> String {
            do {
                let regex = try NSRegularExpression(pattern: matchStr/*, options: .dotMatchesLineSeparators*/)
                var newStr = originStr as NSString
                var range:NSRange = NSRange(location: 0, length: 1)
                
                while range.length > 0 {
                    let match = regex.firstMatch(in: newStr as String, range: NSRange(location: 0, length: newStr.length))
                    range = match?.range ?? NSRange(location: 0, length: 0)
                    if range.length > 0 {
                        if newStr.length < range.length || range.length < 0 {
                            assert(false)
                        }
                        newStr = newStr.replacingCharacters(in: range, with: "") as NSString
                    }
                }
                return newStr as String
            } catch {
                print("\(error)")
                assert(false)
            }
            return ""
        }
        
        
        let filePaths = getFilePath(rootDirectorPath: filePathStr)
        for filePathStr in filePaths {
            let file = FilePath.file(file: filePathStr)
            if let data = try? file.readData(), let codeStr = String(data: data, encoding: .utf8) {
                let newStr = replaceStr(originStr: codeStr, matchStr: "(?<!:)\\/\\/.*|\\/\\*(\\s|.)*?\\*\\/")
                writeStr(filePath: filePathStr, str: newStr)
            }
            let newFile = FilePath.file(file: filePathStr)
            var fileLineItems = (try? newFile.readLines()) ?? []
            fileLineItems.removeAll(where: { str in
                let newStr = str.ignoreEmpty()
                if newStr == "\n" || newStr == "" {
                    return true
                }
                return false
            })
            let newContentStr = fileLineItems.joined(separator: "\n")
            writeStr(filePath: filePathStr, str: newContentStr)
        }
    }
    
    
    
    // 替换类名
    public class func replaceClaseName(filePathStrs:[String], preStr:String) {
//        changeFileAllow(write: true, filePath: filePathStr)
        for filePathStr in filePathStrs {
            replaceCustomStr(filePathStr: filePathStr)
        }
        for filePathStr in filePathStrs {
            deletNote(filePathStr: filePathStr)
        }
        func getReplaceItems(classNode:ClassNode) -> [CLassReplace] {
            let originClassName = classNode.className
            let newClassName = classNode.replaceStr
            var result:[CLassReplace] = []
            let leftExtrTexts:[String] = ["!","@"," ","\n","<", "=",".","(","{","?", ".",":", "[",","]
            
            let rightExtrTexts:[String] = [" ","\n",">", "=",".",")","}","?", ".",":", "]","<","(","{",",", "!"]
            
            for leftExtrText in leftExtrTexts {
                for rightExtrText in rightExtrTexts {
                    if preStr.count > 0 {
                        result.append(CLassReplace(originStr: "\(leftExtrText)\(originClassName)\(rightExtrText)", replaceStr: "\(leftExtrText)\(preStr)_\(originClassName)\(rightExtrText)"))
                    } else {
                        result.append(CLassReplace(originStr: "\(leftExtrText)\(originClassName)\(rightExtrText)", replaceStr: "\(leftExtrText)\(newClassName)\(rightExtrText)"))
                    }
                }
            }
            
            for subClass in classNode.subClass {
                if let next = subClass as? ClassNode {
                    result.append(contentsOf: getReplaceItems(classNode: next))
                }
            }
            
            
            return result
        }

        func replaceStringItem(str:String,replace:CLassReplace) -> String {
            return str.replacingOccurrences(of: replace.originStr, with: replace.replaceStr)
        }
        var fileNodes:[FileNode] = []
        for filePathStr in filePathStrs {
            fileNodes.append(contentsOf: getNodes(filePath: filePathStr))
        }
        var replaceClasss:[CLassReplace] = []
        for fileNode in fileNodes {
            for replaceClass in fileNode.classNodes {
                replaceClasss.append(contentsOf: getReplaceItems(classNode: replaceClass))
            }
        }
        
        for fileNode in fileNodes {
            for replaceClass in replaceClasss {
                fileNode.code = replaceStringItem(str: fileNode.code, replace: replaceClass)
            }
        }
        
        
        self.writeCode(fileNodes: fileNodes)
        for filePathStr in filePathStrs {
            reductionCustomStr(filePathStr: filePathStr)
        }
        CacheData.shared.data.removeAll()
    }
    
    //更改位置+垃圾代码
    public class func exchageLineFileNodes(filePathStrs:[String]) {
        for filePathStr in filePathStrs {
            replaceCustomStr(filePathStr: filePathStr)
        }
        for filePathStr in filePathStrs {
            deletNote(filePathStr: filePathStr)
        }

        var fileNodes:[FileNode] = []
        for filePathStr in filePathStrs {
            fileNodes.append(contentsOf: getNodes(filePath: filePathStr))
        }

        for fileNode in fileNodes {
            let newCode:String = fileNode.getString(addRubbish: true)
            let filePath = FilePath.file(file: fileNode.filePath)
            if let data = newCode.data(using: .utf8) {
                try? filePath.writeData(data)
            }
        }
        for filePathStr in filePathStrs {
            reductionCustomStr(filePathStr: filePathStr)
        }
        CacheData.shared.data.removeAll()
    }
    
    class func changeFileAllow(write:Bool, filePath:String) {
//        let filePaths = getFilePath(rootDirectorPath: filePath)
//        for path in filePaths {
//            let pipe = Pipe()
//            var array = ["-F", "555", path]
//            if write {
//                array = ["-F", "777", path]
//            }
//            let task = Process()
//            task.launchPath = "/bin/chmod";
//            task.arguments = array;
//            task.standardInput = pipe;
//            task.launch()
//            task.waitUntilExit()
//        }
    }
}





