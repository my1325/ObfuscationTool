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
        let inputRootNorm = inputRoot.normalize().string
        let outputRootNorm = outputRoot.normalize().string
        let sameRoot = inputRootNorm == outputRootNorm
        var ensuredDirectories: Set<String> = []

        do {
            try ensureDirectory(outputRoot, ensured: &ensuredDirectories)
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
        let stage1Files = enumerateFiles(inputRoot, includeResourceDirs: true)
        summary.totalFiles = stage1Files.count
        onEvent(.willStart(totalFiles: stage1Files.count))

        for (idx, entry) in stage1Files.enumerated() {
            if token?.isCancelled == true {
                onEvent(.log(message: "Cancelled"))
                onEvent(.didFinish(summary: summary))
                return
            }

            let file = entry.path
            onEvent(.willProcess(path: file.string, index: idx + 1, total: stage1Files.count))
            summary.processedFiles += 1

            do {
                let outPath = try computeOutputPath(
                    inputRoot: inputRoot,
                    inputRootNorm: inputRootNorm,
                    outputRoot: outputRoot,
                    outputRootNorm: outputRootNorm,
                    keepDirectory: config.keepDirectory,
                    inputFile: file,
                    rules: stage1Rules
                )

                try ensureDirectory(outPath.parent(), ensured: &ensuredDirectories)

                if entry.isDirectory {
                    try copyDirectory(from: file, to: outPath)
                    summary.writtenFiles += 1
                    onEvent(.didWrite(path: outPath.string))
                } else {
                    let sourceKey = file.normalize().string
                    let outputKey = outPath.normalize().string
                    if sourceKey == outputKey,
                       !contentProcessor.mayRewriteContent(path: file, rules: stage1Rules) {
                        // 路径相同，且处理器会原样交回字节。
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
                            sourceKey: sourceKey,
                            outputKey: outputKey,
                            sameRoot: sameRoot,
                            ensured: &ensuredDirectories
                        )
                        summary.writtenFiles += 1
                        onEvent(.didWrite(path: outPath.string))
                    }
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
        let stage2RootNorm = outputRootNorm
        let stage2Files = enumerateFiles(stage2InputRoot, includeResourceDirs: false)

        for (idx, entry) in stage2Files.enumerated() {
            if token?.isCancelled == true {
                onEvent(.log(message: "Cancelled"))
                break
            }

            let file = entry.path
            onEvent(.willProcess(path: file.string, index: idx + 1, total: stage2Files.count))
            summary.processedFiles += 1

            do {
                // stage2 直接在输出目录内做 in-place（可能发生 rename）
                let outPath = try computeOutputPath(
                    inputRoot: stage2InputRoot,
                    inputRootNorm: stage2RootNorm,
                    outputRoot: stage2InputRoot,
                    outputRootNorm: stage2RootNorm,
                    keepDirectory: true,
                    inputFile: file,
                    rules: caseConvertRules
                )

                let sourceKey = file.normalize().string
                let outputKey = outPath.normalize().string
                if sourceKey == outputKey,
                   !contentProcessor.mayRewriteContent(path: file, rules: caseConvertRules) {
                    summary.writtenFiles += 1
                    onEvent(.didWrite(path: outPath.string))
                    continue
                }

                let data: Data = try file.read()
                let processed = try contentProcessor.process(
                    path: file,
                    data: data,
                    rules: caseConvertRules
                )
                try ensureDirectory(outPath.parent(), ensured: &ensuredDirectories)
                if outPath.exists { try outPath.delete() }
                try outPath.write(processed)
                summary.writtenFiles += 1
                onEvent(.didWrite(path: outPath.string))

                if outputKey != sourceKey, file.exists {
                    try file.delete()
                }
            } catch {
                summary.errors += 1
                onEvent(.didFail(path: file.string, message: "\(error)"))
            }
        }

        onEvent(.didFinish(summary: summary))
    }

    private func enumerateFiles(_ root: Path, includeResourceDirs: Bool) -> [EnumeratedEntry] {
        guard root.exists else { return [] }
        if root.isFile { return [EnumeratedEntry(path: root, isDirectory: false)] }

        // bundle / lproj 整包复制。xcassets 不整包复制，进入内部逐文件处理。
        return TreeEnumeration.collect(
            under: root,
            includeDirectories: { directory in
                guard includeResourceDirs, let ext = directory.extension else { return false }
                return ext == "bundle" || ext == "lproj"
            },
            includeFiles: { _ in true }
        )
    }

    private func computeOutputPath(
        inputRoot: Path,
        inputRootNorm: String,
        outputRoot: Path,
        outputRootNorm: String,
        keepDirectory: Bool,
        inputFile: Path,
        rules: [Rule]
    ) throws -> Path {
        if keepDirectory, let xcRoot = xcassetsRoot(containing: inputFile, underRootNorm: inputRootNorm) {
            return computeOutputPathInsideXcassets(
                inputRootNorm: inputRootNorm,
                outputRootNorm: outputRootNorm,
                xcRoot: xcRoot,
                inputFile: inputFile,
                rules: rules
            )
        }

        let relativeParent: Path = {
            guard keepDirectory else { return outputRoot }
            let origin = inputFile.parent().normalize().string
            guard origin.hasPrefix(inputRootNorm) else { return outputRoot }
            let rel = origin.dropFirst(inputRootNorm.count)
            return Path(outputRootNorm + String(rel))
        }()

        let transformedName = pathTransformer.transform(inputFile, rules: rules).lastComponent
        return relativeParent + transformedName
    }

    /// 自 `path` 向上查找位于 `root` 之下的 `*.xcassets` 根目录。
    private func xcassetsRoot(containing path: Path, underRootNorm rootNorm: String) -> Path? {
        var node = path
        while true {
            if let ext = node.extension, ext.lowercased() == "xcassets" {
                let normalized = node.normalize()
                guard normalized.string.hasPrefix(rootNorm) else { return nil }
                return normalized
            }
            let parent = node.parent()
            if parent == node || parent.string.count < rootNorm.count { break }
            node = parent
        }
        return nil
    }

    /// 资源目录内路径：对「相对 inputRoot 到 xcassets 根」与「xcassets 内相对路径」整段做路径规则变换，使 imageset / appiconset 等文件夹名与文件一致。
    private func computeOutputPathInsideXcassets(
        inputRootNorm: String,
        outputRootNorm: String,
        xcRoot: Path,
        inputFile: Path,
        rules: [Rule]
    ) -> Path {
        let xcNorm = xcRoot.string
        let fileNorm = inputFile.normalize().string

        let relToXc = String(xcNorm.dropFirst(inputRootNorm.count))
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

        var out = outputRootNorm
        if !prefixTransformed.isEmpty {
            out += prefixTransformed.hasPrefix("/") ? prefixTransformed : "/" + prefixTransformed
        }
        if !innerTransformed.isEmpty {
            out += innerTransformed.hasPrefix("/") ? innerTransformed : "/" + innerTransformed
        }
        return Path(out)
    }

    private func ensureDirectory(_ path: Path, ensured: inout Set<String>) throws {
        let key = path.string
        if ensured.contains(key) { return }
        try path.mkpath()
        ensured.insert(key)
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
        sourceKey: String,
        outputKey: String,
        sameRoot: Bool,
        ensured: inout Set<String>
    ) throws {
        if sourceKey == outputKey {
            let parent = output.parent()
            try ensureDirectory(parent, ensured: &ensured)
            let tmp = parent + ".\(UUID().uuidString).obfuscationtmp"
            try tmp.write(processed)
            if source.exists {
                try source.delete()
            }
            let fm = FileManager.default
            try fm.moveItem(atPath: tmp.string, toPath: output.string)
            return
        }

        try ensureDirectory(output.parent(), ensured: &ensured)
        try output.write(processed)
        if sameRoot, sourceKey != outputKey, source.exists {
            try source.delete()
        }
    }
}

