//
//  main.swift
//  Commond
//
//  Created by mayong on 2023/9/26.
//

import Commander
import PathKit
import SwiftParser

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
//    }/Users/mayong/Desktop/wudi/Remi/Remi/Remi/RemiCK
// }
//
// commandGroup.run()

// [
//    "BF_": "Loop_Video_", "bf_": "loop_video_",
//    "live_": "home_", "Live_": "Home_",
//    "gift_": "long_", "Gift_": "Long_",
//    "premium_": "preview_", "Premium_": "Preview_",
//    "anchor_": "aUser", "Anchor_": "AUser_",
//    "combo_": "cobo_", "Combo_": "Cobo_",
//    "take_": "pop_", "Take_": "Pop_",
//    "pk_": "battle_", "Pk_": "Battle_",
// ]
// [.init(prefix: "BF_", toLowercase: false), .init(prefix: "bf_", toLowercase: true)]
let config = ObfuscationConfig(
//    replace: .init(["Luka_Live_": "NubeLove", "luka_": "nube_"]),
//    replace: .init(
//        [
//            "BF_": "Luka", "bf_": "luka_",
//            "live_": "new_", "Live_": "New_",
//            "gift_": "event_", "Gift_": "Event_",
//            "premium_": "hava_", "Premium_": "Hava_",
//            "anchor_": "lUser", "Anchor_": "LUser_",
//            "combo_": "shift_", "Combo_": "Shift_",
//            "take_": "bring_", "Take_": "Bring_",
//            "pk_": "double_", "Pk_": "Double_",
//        ]
//    ),
//    replace: .init(["HixWeb": "VoyaTravel", "hixweb_": "voyaTravel_"]),
    replace: .init(["Voya": "Peppy", "voya_": "peppy_"]),
//    replace: .init([:]),
//    shuffule: .init(order: true),
    shuffule: nil,
//    camelToSnake: [
//        .init(prefix: "ViewLoop", toLowercase: false),
//        .init(prefix: "DataLoop", toLowercase: false),
//        .init(prefix: "HairLoop", toLowercase: false),
//        .init(prefix: "RequestLoop", toLowercase: false),
//        .init(prefix: "hairLoop_", toLowercase: true),
//        .init(prefix: "lp_", toLowercase: true),
//    ],
//    camelToSnake: [
//        .init(prefix: "BF_", toLowercase: false),
//        .init(prefix: "bf_", toLowercase: true),
//    ],
    camelToSnake: nil,
    snameToCamel: nil,
    zips: nil,
//    input: "/Users/mayong/Downloads/BF_LiveKitSwift",
//    input: "/Users/mayong/Desktop/wudi/BuzzyMy/Buzzy/BuzzyChallenge/code",
//    input: "/Users/mayong/Desktop/wudi/luka/Luka/Luka/Sources/Room",
    input: "/Users/mayong/Desktop/wudi/Peppy/Peppy/Peppy",
//    output: "/Users/mayong/Downloads/BF_LiveKitSwift_1",
//    output: "/Users/mayong/Desktop/wudi/OrenMy/Oren/OrenChat/OrenChat",
    output: "/Users/mayong/Desktop/wudi/Peppy/Peppy/Peppy",
    keepDirectory: true
)


let obTool = Obfuscation(config: config)
try obTool.run()

// let file = Path("/Users/mayong/Desktop/wudi/LiveKitSwift/BF_LiveKitSwift/Business/view/GiftAbout/NewGiftBoard/BF_NewGiftBoardView.swift")
// let source: String = try file.read()
// var parser = Parser.parse(source: source)
// let prefixWriter = PrefixRewriter(prefix: "bf_")
// let output = prefixWriter.rewrite(parser)
// try file.write(output.description, encoding: .utf8)
