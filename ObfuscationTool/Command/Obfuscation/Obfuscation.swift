//
//  Obfuscation.swift
//  Command
//
//  Created by mayong on 2023/9/27.
//

import Foundation
import PathKit
import Plugins
import ProcessingFiles
import SwiftFilePlugin
import ObfuscationCore

final class Obfuscation {
    let config: ObfuscationConfig
    init(config: ObfuscationConfig) {
        self.config = config
    }

    var input: Path {
        Path.current + (config.input ?? "")
    }

    var output: Path {
        if let output = config.output, !output.isEmpty {
            return Path.current + output
        }
        return input
    }

    var keepDirectory: Bool {
        config.keepDirectory ?? false
    }

    func run() throws {
        let input = input

        if !input.exists {
            throw ObfuscationError.inputNotExists(input.string)
        }

        let outputPath = try checkOutput()
        let rules = buildRules()

        let runner = Runner()
        let project = ProjectConfig(
            input: input.normalize().string,
            output: outputPath.normalize().string,
            keepDirectory: keepDirectory,
            rules: rules
        )

        runner.run(config: project) { _ in
            // CLI 默认静默；需要时可在这里输出 progress/log
        }
    }

    func scanPrefixes() throws -> PrefixScanResult {
        let input = input
        if !input.exists {
            throw ObfuscationError.inputNotExists(input.string)
        }
        let rules = buildRules()
        return PrefixScanner().scan(inputRoot: input, rules: rules)
    }

    func validate() throws {
        let input = input
        if !input.exists {
            throw ObfuscationError.inputNotExists(input.string)
        }
        _ = try checkOutput()
        _ = buildRules()
    }

    private func buildRules() -> [Rule] {
        var rules: [Rule] = []

        if let replace = config.replace, let map = replace.map, !map.isEmpty {
            let applyToPath = replace.targets?.path ?? true
            let applyToContent = replace.targets?.content ?? true
            var targets: Set<RuleTarget> = []
            if applyToPath { targets.insert(.path) }
            if applyToContent { targets.insert(.content) }
            if targets.isEmpty { targets = [.path, .content] }

            rules.append(
                Rule(
                    enabled: true,
                    appliesTo: targets,
                    scope: .init(
                        onlyPrefix: false,
                        onlyFilename: false
                    ),
                    kind: .replace(map: map)
                )
            )
        }

        if let camelToSnake = config.camelToSnake {
            for item in camelToSnake {
                let applyToPath = item.targets?.path ?? true
                let applyToContent = item.targets?.content ?? true
                var targets: Set<RuleTarget> = []
                if applyToPath { targets.insert(.path) }
                if applyToContent { targets.insert(.content) }
                if targets.isEmpty { targets = [.path, .content] }

                rules.append(
                    Rule(
                        enabled: true,
                        appliesTo: targets,
                        scope: .init(),
                        kind: .caseConvert(prefix: item.prefix, toLowercase: item.toLowercase ?? true, direction: .camelToSnake)
                    )
                )
            }
        }

        if let snakeToCamel = config.snameToCamel {
            for item in snakeToCamel {
                let applyToPath = item.targets?.path ?? true
                let applyToContent = item.targets?.content ?? true
                var targets: Set<RuleTarget> = []
                if applyToPath { targets.insert(.path) }
                if applyToContent { targets.insert(.content) }
                if targets.isEmpty { targets = [.path, .content] }

                rules.append(
                    Rule(
                        enabled: true,
                        appliesTo: targets,
                        scope: .init(),
                        kind: .caseConvert(prefix: item.prefix, toLowercase: item.toLowercase ?? true, direction: .snakeToCamel)
                    )
                )
            }
        }

        if let shuffle = config.shuffule {
            rules.append(
                Rule(
                    enabled: true,
                    appliesTo: [.swiftStructure],
                    scope: .init(),
                    kind: .shuffle(orderAware: true)
                )
            )
        }

        return rules
    }

    private func checkOutput() throws -> Path {
        let outputPath = output
        if outputPath.exists && !outputPath.isDirectory {
            throw ObfuscationError.outputIsNotValid(outputPath.string)
        }

        try outputPath.mkpath()
        return outputPath
    }

    private func shuffulePlugin(_ config: ObfuscationShuffule) -> SwiftFileProcessingHandlePluginProtocol {
        FileShuffleHandlePlugin(order: config.order ?? false)
    }

    private func fileStringHandlePlugin(
        _ config: ObfuscationReplace?,
        camelToSnake: [ObfuscationCamelToSnake]?,
        snameToCamel: [ObfuscationCamelToSnake]?
    ) -> SwiftFileProcessingHandlePluginProtocol {
        var modes: [FileStringHandlePlugin.HandleMode] = []
        if let config {
            let configModes: [FileStringHandlePlugin.HandleMode] = config.map?
                .keys
                .map { $0 }
                .sorted { $0.count > $1.count }
                .map {
                    FileStringHandlePlugin.HandleMode.replace(
                        prefixOnly: config.onlyPrefix ?? false,
                        originString: $0,
                        replaceString: config.map?[$0] ?? ""
                    )
                } ?? []

            modes += configModes
        }

        if let camelToSnake, !camelToSnake.isEmpty {
            let configModes: [FileStringHandlePlugin.HandleMode] = camelToSnake
                .map {
                    FileStringHandlePlugin.HandleMode.camelToSnake(
                        handlePrefix: $0.prefix,
                        toLowercase: $0.toLowercase ?? true
                    )
                }

            modes += configModes
        }

        if let snameToCamel, !snameToCamel.isEmpty {
            let configModes: [FileStringHandlePlugin.HandleMode] = snameToCamel
                .map {
                    FileStringHandlePlugin.HandleMode.snakeToCamel(
                        handlePrefix: $0.prefix,
                        toLowercase: $0.toLowercase ?? true
                    )
                }

            modes += configModes
        }

        return FileStringHandlePlugin(modes)
    }

    private func swiftFilePlugins() -> SwiftFileProcessingPlugin {
        var plugins: [SwiftFileProcessingHandlePluginProtocol] = []

        plugins.append(
            fileStringHandlePlugin(
                config.replace,
                camelToSnake: config.camelToSnake,
                snameToCamel: config.snameToCamel
            )
        )

        if let shuffle = config.shuffule {
            plugins.append(shuffulePlugin(shuffle))
        }

        return SwiftFileProcessingPlugin(plugins: plugins)
    }

    private func ocFilePlugin() -> OCFileProcessingPlugin {
        var modes: [OCFileProcessingPlugin.HandleMode] = []
        if let replace = config.replace {
            let configModes: [OCFileProcessingPlugin.HandleMode] = replace.map?
                .keys
                .map { $0 }
                .sorted { $0.count > $1.count }
                .map {
                    OCFileProcessingPlugin.HandleMode.replace(
                        prefixOnly: replace.onlyPrefix ?? false,
                        originString: $0,
                        replaceString: replace.map?[$0] ?? ""
                    )
                } ?? []
            modes += configModes
        }

        if let camelToSnake = config.camelToSnake, !camelToSnake.isEmpty {
            let configModes: [OCFileProcessingPlugin.HandleMode] = camelToSnake
                .map {
                    OCFileProcessingPlugin.HandleMode.camelToSnake(
                        handlePrefix: $0.prefix,
                        toLowercase: $0.toLowercase ?? true
                    )
                }
            modes += configModes
        }

        if let snameToCamel = config.snameToCamel, !snameToCamel.isEmpty {
            let configModes: [OCFileProcessingPlugin.HandleMode] = snameToCamel
                .map {
                    OCFileProcessingPlugin.HandleMode.snakeToCamel(
                        handlePrefix: $0.prefix,
                        toLowercase: $0.toLowercase ?? true
                    )
                }
            modes += configModes
        }

        return OCFileProcessingPlugin(modes)
    }

    private func run(_ filePath: Path, onlyFilename: Bool = false) throws {
        let processingManager = ProcessingManager(path: filePath)
        processingManager.registerPlugin(swiftFilePlugins(), forFileType: .swift)
        let ocPlugin = ocFilePlugin()
        processingManager.registerPlugin(ocPlugin, forFileType: .header)
        processingManager.registerPlugin(ocPlugin, forFileType: .implemention)
        if let replace = config.replace {
            processingManager.registerPlugin(NameReplacePlugin(replace), forFileType: .all)
        }

        if let camelToSnake = config.camelToSnake, !camelToSnake.isEmpty {
            processingManager.registerPlugin(NameCamelToSnakePlugin(camelToSnake, onlyFilename: onlyFilename), forFileType: .all)
        }

        if let snameToCamel = config.snameToCamel, !snameToCamel.isEmpty {
            processingManager
                .registerPlugin(
                    NameSnakeToCamelPlugin(snameToCamel, onlyFilename: onlyFilename),
                    forFileType: .all
                )
        }

        processingManager.delegate = self

        let files = try processingManager.processing()

        for file in files {
            guard !file.filePath.lastComponent.starts(with: ".") else {
                continue
            }
            try saveFile(file, in: getOutputPath(file))
        }
    }

    private func getOutputPath(_ file: ProcessingFile) throws -> Path {
        guard keepDirectory else { return output }
        let originPath = file.filePath.normalize().string
        let inputPath = input.normalize().string
        guard originPath.hasPrefix(inputPath) else {
            return output
        }
        let relative = originPath.dropFirst(inputPath.count)
        return Path(output.normalize().string + String(relative)).parent()
    }

    private func saveFile(_ file: ProcessingFile, in path: Path) throws {
        let newPath = path + file.output.lastComponent
        try newPath.parent().mkpath()

        if newPath.exists {
            try newPath.delete()
        }

        if file.fileType.isCode {
            try newPath.write(file.getContent())
        } else {
            try newPath.write(file.getData())
        }

        // 默认不删除源文件：输出到新目录时保持输入目录只读更安全
    }
}

extension Obfuscation: ProcessingManagerDelegate {
    func processingManager(_ manager: ProcessingManager, willProcessing file: Path) {}

    private func isHandledFile(_ fileType: FileType) -> Bool {
        switch fileType {
        case .header, .implemention: return false
        default: return true
        }
    }
}
