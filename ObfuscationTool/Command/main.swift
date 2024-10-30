//
//  main.swift
//  Commond
//
//  Created by mayong on 2023/9/26.
//

import Commander
import PathKit

// let currentWorkSpace = DirectoryPath(path: "/Users/my/Desktop/mulitbeam/")
// let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/wudi/FstWear/multibeam")
// let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/wudi/FstWear/dynamic")
// let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/wudi/FstWear/live")
// let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/DCR_Main")

// let currentWorkSpace = DirectoryPath(path: "/Users/mayong/Desktop/wudi/Lottie/Lottie/Lottie/LiveAbout")

// let currentWorkSpace = Path("/Users/mayong/Downloads/Foam")
//
//
// private let YESEnum = ["yes", "Yes", "YES", "true", "True", "TRUE"]
// private let NOEnum = ["no", "No", "NO", "false", "False", "FALSE"]
// extension Bool: ArgumentConvertible {
//    public init(parser: ArgumentParser) throws {
//        if let value = parser.shift() {
//            if YESEnum.contains(value) {
//                self = true
//            } else if NOEnum.contains(value) {
//                self = false
//            } else {
//                throw ObfuscationError.unknownArgument(value, "Bool")
//            }
//        } else {
//            throw ArgumentError.missingValue(argument: nil)
//        }
//    }
// }
//
// let commandGroup = Group {
//    $0.command("init",
//               Option("template", default: "live", flag: "t"),
//               Option("forceCreate", default: false, flag: "f")) {
//        do {
//            let yamlHandler = YAMLHandler.handlerWithWorkSpace(currentWorkSpace, template: try .init(rawValue: $0))
//            try yamlHandler.createYamlFromTemplatesIfNotExists($1)
//            print("init success")
//        } catch {
//            print("\(error)")
//        }
//    }
//
//    $0.command("run",
//    Option("path", default: "", flag: "p")) { path in
//        do {
//            var fullPath = path
//            if path.isEmpty {
//                fullPath = currentWorkSpace.path
//            }
//            let yamlHandler = YAMLHandler.handlerWithWorkSpace(DirectoryPath(path: fullPath), template: .live)
//            let yamlConfig = try yamlHandler.loadYaml()
//
//            let obfuscation = Obfuscation(config: yamlConfig)
//            try obfuscation.run()
//            print("run success")
//        } catch {
//            print("\(error)")
//        }
//    }
// }
//
// commandGroup.run()

 let config = ObfuscationConfig(
    replace: .init(["Esp": "Anopse_", "esp_": "anopse_"], onlyPrefix: false, onlyFilename: false),
    shuffule: .init(order: true),
    zips: nil,
    input: "/Users/mayong/Desktop/wudi/Espona/Anopse/Anopse",
    output: "",
    keepDirectory: true
 )

 let obTool = Obfuscation(config: config)
 try obTool.run()
