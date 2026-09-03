import Foundation
import PathKit

public struct RunSummary: Sendable {
    public var totalFiles: Int
    public var processedFiles: Int
    public var writtenFiles: Int
    public var errors: Int

    public init(totalFiles: Int = 0, processedFiles: Int = 0, writtenFiles: Int = 0, errors: Int = 0) {
        self.totalFiles = totalFiles
        self.processedFiles = processedFiles
        self.writtenFiles = writtenFiles
        self.errors = errors
    }
}

public enum RunnerEvent: Sendable {
    case willStart(totalFiles: Int)
    case willProcess(path: String, index: Int, total: Int)
    case didWrite(path: String)
    case log(message: String)
    case didFail(path: String, message: String)
    case didFinish(summary: RunSummary)
}

public final class CancellationToken: @unchecked Sendable {
    private let lock = NSLock()
    private var _isCancelled: Bool = false

    public init() {}

    public var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isCancelled
    }

    public func cancel() {
        lock.lock(); defer { lock.unlock() }
        _isCancelled = true
    }
}

public final class Runner {
    private let pathTransformer: PathTransformer
    private let contentProcessor: ContentProcessor

    public init(
        pathTransformer: PathTransformer = .init(),
        contentProcessor: ContentProcessor = .init()
    ) {
        self.pathTransformer = pathTransformer
        self.contentProcessor = contentProcessor
    }

    public func run(
        config: ProjectConfig,
        token: CancellationToken? = nil,
        onEvent: @Sendable (RunnerEvent) -> Void
    ) {
        var summary = RunSummary()

        let inputRoot = Path(config.input)
        let outputRoot = Path(config.output)

        do {
            try outputRoot.mkpath()
        } catch {
            onEvent(.didFail(path: outputRoot.string, message: "\(error)"))
            onEvent(.didFinish(summary: summary))
            return
        }

        let caseConvertRules = config.rules.filter {
            if case .caseConvert = $0.kind { return true }
            return false
        }
        let stage1Rules = config.rules.filter {
            if case .caseConvert = $0.kind { return false }
            return true
        }

        // Stage 1: Replace + Shuffle（以及其他非 CaseConvert）
        let stage1Files: [Path] = enumerateFiles(inputRoot, includeResourceDirs: true)
        summary.totalFiles = stage1Files.count
        onEvent(.willStart(totalFiles: stage1Files.count))

        for (idx, file) in stage1Files.enumerated() {
            if token?.isCancelled == true {
                onEvent(.log(message: "Cancelled"))
                onEvent(.didFinish(summary: summary))
                return
            }

            onEvent(.willProcess(path: file.string, index: idx + 1, total: stage1Files.count))
            summary.processedFiles += 1

            do {
                let outPath = try computeOutputPath(
                    inputRoot: inputRoot,
                    outputRoot: outputRoot,
                    keepDirectory: config.keepDirectory,
                    inputFile: file,
                    rules: stage1Rules
                )

                try outPath.parent().mkpath()

                if file.isDirectory {
                    try copyDirectory(from: file, to: outPath)
                    summary.writtenFiles += 1
                    onEvent(.didWrite(path: outPath.string))
                } else {
                    let data: Data = try file.read()
                    let processed = try contentProcessor.process(
                        path: file,
                        data: data,
                        rules: stage1Rules
                    )
                    try writeStage1RegularFileReplacingSourceIfNeeded(
                        processed: processed,
                        source: file,
                        output: outPath,
                        inputRoot: inputRoot,
                        outputRoot: outputRoot
                    )
                    summary.writtenFiles += 1
                    onEvent(.didWrite(path: outPath.string))
                }
            } catch {
                summary.errors += 1
                onEvent(.didFail(path: file.string, message: "\(error)"))
            }
        }

        // Stage 2: CaseConvert（独立流程，作用于 stage1 的输出目录）
        guard !caseConvertRules.isEmpty else {
            onEvent(.didFinish(summary: summary))
            return
        }

        onEvent(.log(message: "Stage2: CaseConvert"))
        let stage2InputRoot = outputRoot
        let stage2Files: [Path] = enumerateFiles(stage2InputRoot, includeResourceDirs: false)

        for (idx, file) in stage2Files.enumerated() {
            if token?.isCancelled == true {
                onEvent(.log(message: "Cancelled"))
                break
            }

            onEvent(.willProcess(path: file.string, index: idx + 1, total: stage2Files.count))
            summary.processedFiles += 1

            do {
                // stage2 直接在输出目录内做 in-place（可能发生 rename）
                let outPath = try computeOutputPath(
                    inputRoot: stage2InputRoot,
                    outputRoot: stage2InputRoot,
                    keepDirectory: true,
                    inputFile: file,
                    rules: caseConvertRules
                )

                let data: Data = try file.read()
                let processed = try contentProcessor.process(
                    path: file,
                    data: data,
                    rules: caseConvertRules
                )
                try outPath.parent().mkpath()
                if outPath.exists { try outPath.delete() }
                try outPath.write(processed)
                summary.writtenFiles += 1
                onEvent(.didWrite(path: outPath.string))

                if outPath.normalize() != file.normalize(), file.exists {
                    try file.delete()
                }
            } catch {
                summary.errors += 1
                onEvent(.didFail(path: file.string, message: "\(error)"))
            }
        }

        onEvent(.didFinish(summary: summary))
    }

    private func enumerateFiles(_ root: Path, includeResourceDirs: Bool) -> [Path] {
        guard root.exists else { return [] }
        if root.isFile { return [root] }

        var files: [Path] = []
        let fm = FileManager.default
        let base = root.string
        let enumerator = fm.enumerator(atPath: base)
        while let rel = enumerator?.nextObject() as? String {
            guard !rel.isEmpty else { continue }
            if rel.split(separator: "/").contains(where: { $0.hasPrefix(".") }) {
                enumerator?.skipDescendants()
                continue
            }
            let p = Path(base + "/" + rel)
            if p.isDirectory {
                // 目录也作为处理对象（用于 bundle / lproj 整体复制）。
                // xcassets 不整包复制：进入内部逐文件处理，以便 imageset 目录名与 Contents.json 随规则改名。
                if includeResourceDirs, let ext = p.extension, ["bundle", "lproj"].contains(ext) {
                    files.append(p)
                    enumerator?.skipDescendants()
                }
                continue
            }
            if p.isFile {
                files.append(p)
            }
        }
        return files
    }

    private func computeOutputPath(
        inputRoot: Path,
        outputRoot: Path,
        keepDirectory: Bool,
        inputFile: Path,
        rules: [Rule]
    ) throws -> Path {
        if keepDirectory, let xcRoot = xcassetsRoot(containing: inputFile, under: inputRoot) {
            return computeOutputPathInsideXcassets(
                inputRoot: inputRoot,
                outputRoot: outputRoot,
                xcRoot: xcRoot,
                inputFile: inputFile,
                rules: rules
            )
        }

        let relativeParent: Path = {
            guard keepDirectory else { return outputRoot }
            let origin = inputFile.parent().normalize().string
            let base = inputRoot.normalize().string
            guard origin.hasPrefix(base) else { return outputRoot }
            let rel = origin.dropFirst(base.count)
            return Path(outputRoot.normalize().string + String(rel))
        }()

        let transformedName = pathTransformer.transform(inputFile, rules: rules).lastComponent
        return relativeParent + transformedName
    }

    /// 自 `path` 向上查找位于 `root` 之下的 `*.xcassets` 根目录。
    private func xcassetsRoot(containing path: Path, under root: Path) -> Path? {
        var node = path
        let rootNorm = root.normalize().string
        while true {
            if let ext = node.extension, ext.lowercased() == "xcassets" {
                let n = node.normalize().string
                guard n.hasPrefix(rootNorm) else { return nil }
                return node.normalize()
            }
            let parent = node.parent()
            if parent == node || parent.string.count < rootNorm.count { break }
            node = parent
        }
        return nil
    }

    /// 资源目录内路径：对「相对 inputRoot 到 xcassets 根」与「xcassets 内相对路径」整段做路径规则变换，使 imageset / appiconset 等文件夹名与文件一致。
    private func computeOutputPathInsideXcassets(
        inputRoot: Path,
        outputRoot: Path,
        xcRoot: Path,
        inputFile: Path,
        rules: [Rule]
    ) -> Path {
        let inRoot = inputRoot.normalize().string
        let xcNorm = xcRoot.normalize().string
        let fileNorm = inputFile.normalize().string

        let relToXc = String(xcNorm.dropFirst(inRoot.count))
        let relToXcTrimmed = relToXc.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let prefixTransformed: String = {
            guard !relToXcTrimmed.isEmpty else { return "" }
            let p = Path(relToXcTrimmed)
            return pathTransformer.transform(p, rules: rules).string
        }()

        let inner = String(fileNorm.dropFirst(xcNorm.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let innerTransformed: String = {
            guard !inner.isEmpty else { return "" }
            return pathTransformer.transform(Path(inner), rules: rules).string
        }()

        let outBase = outputRoot.normalize().string
        var out = outBase
        if !prefixTransformed.isEmpty {
            out += prefixTransformed.hasPrefix("/") ? prefixTransformed : "/" + prefixTransformed
        }
        if !innerTransformed.isEmpty {
            out += innerTransformed.hasPrefix("/") ? innerTransformed : "/" + innerTransformed
        }
        return Path(out)
    }

    private func copyDirectory(from src: Path, to dst: Path) throws {
        let fm = FileManager.default
        if dst.exists { try dst.delete() }
        try fm.copyItem(atPath: src.string, toPath: dst.string)
    }

    /// 仅针对普通文件：按「每个文件」判断是否原路径输出并处理源文件。
    /// - 该文件输出路径与源路径相同：先写入同目录临时文件，再删除源路径，再移回目标路径（避免原地覆盖语义不清）。
    /// - 输出路径不同且输入/输出同根：写入新路径后删除旧源路径，避免改名残留。
    private func writeStage1RegularFileReplacingSourceIfNeeded(
        processed: Data,
        source: Path,
        output: Path,
        inputRoot: Path,
        outputRoot: Path
    ) throws {
        let srcKey = source.normalize().string
        let outKey = output.normalize().string

        if srcKey == outKey {
            let parent = output.parent()
            try parent.mkpath()
            let tmp = parent + ".\(UUID().uuidString).obfuscationtmp"
            try tmp.write(processed)
            if source.exists {
                try source.delete()
            }
            let fm = FileManager.default
            try fm.moveItem(atPath: tmp.string, toPath: output.string)
            return
        }

        try output.parent().mkpath()
        try output.write(processed)
        try deleteSourceAfterInPlaceRenameIfNeeded(
            inputRoot: inputRoot,
            outputRoot: outputRoot,
            source: source,
            output: output
        )
    }

    /// 同根目录且该文件输出路径与源路径不同时，写入成功后删除旧源路径。
    private func deleteSourceAfterInPlaceRenameIfNeeded(
        inputRoot: Path,
        outputRoot: Path,
        source: Path,
        output: Path
    ) throws {
        guard inputRoot.normalize().string == outputRoot.normalize().string else { return }
        guard source.normalize().string != output.normalize().string else { return }
        guard source.exists else { return }
        try source.delete()
    }
}

