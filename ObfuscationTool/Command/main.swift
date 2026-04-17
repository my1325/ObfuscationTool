//
//  main.swift
//  Commond
//
//  Created by mayong on 2023/9/26.
//

import Foundation
import Commander
import PathKit
import SwiftParser

private func loadConfig(from path: Path) throws -> ObfuscationConfig {
    let data = try Data(contentsOf: URL(fileURLWithPath: path.string))
    return try JSONDecoder().decode(ObfuscationConfig.self, from: data)
}

let commandGroup = Group {
    $0.command(
        "run",
        Option("config", default: "obfuscation.json", flag: "c", description: "配置文件路径（JSON）")
    ) { configPath in
        do {
            let configFile = Path.current + configPath
            guard configFile.exists else {
                throw ObfuscationError.inputNotExists(configFile.string)
            }
            let config = try loadConfig(from: configFile)
            let obTool = Obfuscation(config: config)
            try obTool.run()
            print("run success")
        } catch {
            print("\(error)")
        }
    }
}

commandGroup.run()
