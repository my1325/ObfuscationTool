//
//  main.swift
//  Commond
//
//  Created by mayong on 2023/9/26.
//

import Commander
import FilePath

//let currentWorkSpace = DirectoryPath(path: "/Users/my/Desktop/mulitbeam/")
//let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/wudi/FstWear/multibeam")
//let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/wudi/FstWear/dynamic")
//let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/wudi/FstWear/live")
//let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/DCR_Main")

//let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/wudi/Lottie/Lottie/Lottie/LiveAbout")

let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/wudi/Danrt/Danrt/")


private let YESEnum = ["yes", "Yes", "YES", "true", "True", "TRUE"]
private let NOEnum = ["no", "No", "NO", "false", "False", "FALSE"]
extension Bool: ArgumentConvertible {
    public init(parser: ArgumentParser) throws {
        if let value = parser.shift() {
            if YESEnum.contains(value) {
                self = true
            } else if NOEnum.contains(value) {
                self = false
            } else {
                throw ObfuscationError.unknownArgument(value, "Bool")
            }
        } else {
            throw ArgumentError.missingValue(argument: nil)
        }
    }
}

let commandGroup = Group {
    $0.command("init",
               Option("template", default: "live", flag: "t"),
               Option("forceCreate", default: false, flag: "f")) {
        do {
            let yamlHandler = YAMLHandler.handlerWithWorkSpace(currentWorkSpace, template: try .init(rawValue: $0))
            try yamlHandler.createYamlFromTemplatesIfNotExists($1)
            print("init success")
        } catch {
            print("\(error)")
        }
    }

    $0.command("run",
               Option("template", default: "live", flag: "t")) {
        do {
            let yamlHandler = YAMLHandler.handlerWithWorkSpace(currentWorkSpace, template: try .init(rawValue: $0))
            let yamlConfig = try yamlHandler.loadYaml()
            
            let obfuscation = Obfuscation(config: yamlConfig)
            try obfuscation.run()
            print("run success")
        } catch {
            print("\(error)")
        }
    }
}

commandGroup.run()
