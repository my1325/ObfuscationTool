//
//  InitCommandFile.swift
//  Commond
//
//  Created by mayong on 2023/9/26.
//

import Foundation
import Yams
import PathKit


//internal final class YAMLHandler {
//    static var handlerCache: [FilePath: YAMLHandler] = [:]
//    
//    static func handlerWithWorkSpace(_ workspace: Path, template: TemplateType) -> YAMLHandler {
////        let filePath = workspace.appendFileName(template.name, ext: "yml") as! FilePath
////        if let handler = handlerCache[filePath] {
////            return handler
////        }
//        let handler = YAMLHandler(currentDirectory: workspace, template: template)
////        handlerCache[filePath] = handler
//        return handler
//    }
//    
//    let currentDirectory: DirectoryPathProtocol
//    let configFilePath: FilePathProtocol
//    let template: TemplateType
//    private init(currentDirectory: DirectoryPath = .current, template: TemplateType) {
//        self.currentDirectory = currentDirectory
//        self.configFilePath = currentDirectory.appendFileName("", ext: "yml")
//        self.template = template
//    }
//    
//    func createYamlFromTemplatesIfNotExists(_ isForce: Bool = false) throws {
//        guard !configFilePath.isExists || isForce else { return }
//        try configFilePath.createIfNotExists()
////        if let templatesData = template.template.data(using: .utf8) {
////            try configFilePath.writeData(templatesData)
////        }
//    }
//
//    func loadYaml(_ decoder: YAMLDecoder = YAMLDecoder()) throws -> ObfuscationConfig {
//        let yamlString = try configFilePath.readLines().joined(separator: "\n")
//        return try decoder.decode(from: yamlString)
//    }
//}
