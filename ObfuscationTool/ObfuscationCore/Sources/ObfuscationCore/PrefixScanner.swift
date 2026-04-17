import Foundation
import PathKit
import SwiftParser
import SwiftSyntax
import SwiftFilePlugin

public enum PrefixSymbolKind: String, CaseIterable, Hashable, Sendable {
    case typeClass
    case typeStruct
    case typeEnum
    case typeProtocol
    case typeActor
    case function
    case variable
}

public struct PrefixHit: Hashable, Sendable {
    public let prefix: String
    public let count: Int
    public let samples: [String]
}

public struct PrefixScanResult: Sendable {
    public let officialPrefixes: Set<String>
    public let hitsByKind: [PrefixSymbolKind: [PrefixHit]]
}

public struct PrefixScanner: Sendable {
    public init() {}

    public func scan(
        inputRoot: Path,
        rules: [Rule]
    ) -> PrefixScanResult {
        let official = officialPrefixSet(from: rules)

        let files = enumerateSwiftFiles(inputRoot)
        var buckets: [PrefixSymbolKind: [String: (count: Int, samples: [String])]] = [:]

        for file in files {
            guard let source: String = try? file.read() else { continue }
            var parser = Parser(source)
            let syntax = SourceFileSyntax.parse(from: &parser)

            let walker = SwiftSyntaxWalker(
                supportSyntaxDecls: [
                    .class, .struct, .enum, .protocol, .actor,
                    .func, .variable,
                ],
                syntaxNode: syntax
            )

            for node in walker.walk() {
                let (kind, name) = classify(node)
                guard let kind, let name, !name.isEmpty else { continue }
                guard let prefix = extractPrefix(name) else { continue }
                guard !official.contains(prefix) else { continue }
                addHit(kind: kind, prefix: prefix, sample: name, to: &buckets)
            }
        }

        let hitsByKind: [PrefixSymbolKind: [PrefixHit]] = Dictionary(
            uniqueKeysWithValues: PrefixSymbolKind.allCases.map { kind in
                let map = buckets[kind] ?? [:]
                let hits = map
                    .map { key, value in
                        PrefixHit(prefix: key, count: value.count, samples: Array(value.samples.prefix(10)))
                    }
                    .sorted {
                        if $0.count != $1.count { return $0.count > $1.count }
                        return $0.prefix < $1.prefix
                    }
                return (kind, hits)
            }
        )

        return PrefixScanResult(
            officialPrefixes: official,
            hitsByKind: hitsByKind
        )
    }

    // MARK: - Official prefixes

    private func officialPrefixSet(from rules: [Rule]) -> Set<String> {
        var ret: Set<String> = []
        for rule in rules where rule.enabled {
            switch rule.kind {
            case let .replace(map):
                for k in map.keys {
                    if let p = normalizePrefixCandidate(k) { ret.insert(p) }
                }
            case let .caseConvert(prefix, _, _):
                if let p = normalizePrefixCandidate(prefix) { ret.insert(p) }
            case .shuffle:
                break
            }
        }
        return ret
    }

    private func normalizePrefixCandidate(_ s: String) -> String? {
        if s.isEmpty { return nil }
        if s.hasSuffix("_") { return s }
        // 允许用户在规则里写 “BF” 也算官方，统一当作 “BF_”
        if s.allSatisfy({ $0.isLetter || $0.isNumber }) { return s + "_" }
        return nil
    }

    // MARK: - File enumeration

    private func enumerateSwiftFiles(_ root: Path) -> [Path] {
        guard root.exists else { return [] }
        if root.isFile { return root.extension == "swift" ? [root] : [] }

        let fm = FileManager.default
        let base = root.string
        let enumerator = fm.enumerator(atPath: base)
        var files: [Path] = []

        while let rel = enumerator?.nextObject() as? String {
            if rel.split(separator: "/").contains(where: { $0.hasPrefix(".") }) {
                enumerator?.skipDescendants()
                continue
            }
            let p = Path(base + "/" + rel)
            if p.isDirectory { continue }
            if p.isFile, p.extension == "swift" {
                files.append(p)
            }
        }
        return files
    }

    // MARK: - Node classification

    private func classify(_ node: SyntaxProtocol) -> (PrefixSymbolKind?, String?) {
        if let n = node as? ClassDeclSyntax { return (.typeClass, n.name.text) }
        if let n = node as? StructDeclSyntax { return (.typeStruct, n.name.text) }
        if let n = node as? EnumDeclSyntax { return (.typeEnum, n.name.text) }
        if let n = node as? ProtocolDeclSyntax { return (.typeProtocol, n.name.text) }
        if let n = node as? ActorDeclSyntax { return (.typeActor, n.name.text) }
        if let n = node as? FunctionDeclSyntax { return (.function, n.name.text) }
        if let n = node as? VariableDeclSyntax { return (.variable, n.syntaxName) }
        return (nil, nil)
    }

    // MARK: - Prefix heuristic

    private func extractPrefix(_ identifier: String) -> String? {
        // 只识别 underscore 前缀：BF_Foo / bf_bar
        guard let idx = identifier.firstIndex(of: "_") else { return nil }
        let head = identifier[..<idx]
        let prefix = String(head) + "_"

        // 过滤过短/过长与非法字符（减少噪音）
        if head.count < 2 || head.count > 8 { return nil }
        guard head.allSatisfy({ $0.isLetter || $0.isNumber }) else { return nil }
        return prefix
    }

    private func addHit(
        kind: PrefixSymbolKind,
        prefix: String,
        sample: String,
        to buckets: inout [PrefixSymbolKind: [String: (count: Int, samples: [String])]]
    ) {
        var map = buckets[kind] ?? [:]
        var entry = map[prefix] ?? (0, [])
        entry.count += 1
        if entry.samples.count < 10, !entry.samples.contains(sample) {
            entry.samples.append(sample)
        }
        map[prefix] = entry
        buckets[kind] = map
    }
}

