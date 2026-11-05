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
        rules: [Rule],
        isCancelled: @Sendable () -> Bool = { false }
    ) -> PrefixScanResult {
        let official = officialPrefixSet(from: rules)

        let files = enumerateSwiftFiles(inputRoot)
        var buckets: [PrefixSymbolKind: KindBuckets] = [:]

        for file in files {
            if isCancelled() { break }
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
                let map = buckets[kind]?.byPrefix ?? [:]
                let hits = map
                    .map { key, value in
                        PrefixHit(prefix: key, count: value.count, samples: value.samples)
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

        return TreeEnumeration.collect(
            under: root,
            includeDirectories: { _ in false },
            includeFiles: { $0.extension == "swift" }
        ).map(\.path)
    }

    // MARK: - Node classification

    private func classify(_ node: SyntaxProtocol) -> (PrefixSymbolKind?, String?) {
        switch node._syntaxNode.as(SyntaxEnum.self) {
        case let .classDecl(n): return (.typeClass, n.name.text)
        case let .structDecl(n): return (.typeStruct, n.name.text)
        case let .enumDecl(n): return (.typeEnum, n.name.text)
        case let .protocolDecl(n): return (.typeProtocol, n.name.text)
        case let .actorDecl(n): return (.typeActor, n.name.text)
        case let .functionDecl(n): return (.function, n.name.text)
        case let .variableDecl(n): return (.variable, n.syntaxName)
        default: return (nil, nil)
        }
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

    /// 用类保存计数，避免每次命中都复制整张前缀表。
    /// 以前每个符号都会拷贝一次字典，扫描成本随命中数变成平方。
    private final class PrefixBucket {
        var count = 0
        var samples: [String] = []
    }

    private final class KindBuckets {
        var byPrefix: [String: PrefixBucket] = [:]

        func add(prefix: String, sample: String) {
            let bucket: PrefixBucket
            if let existing = byPrefix[prefix] {
                bucket = existing
            } else {
                let created = PrefixBucket()
                byPrefix[prefix] = created
                bucket = created
            }
            bucket.count += 1
            if bucket.samples.count < 10, !bucket.samples.contains(sample) {
                bucket.samples.append(sample)
            }
        }
    }

    private func addHit(
        kind: PrefixSymbolKind,
        prefix: String,
        sample: String,
        to buckets: inout [PrefixSymbolKind: KindBuckets]
    ) {
        let kindBucket: KindBuckets
        if let existing = buckets[kind] {
            kindBucket = existing
        } else {
            let created = KindBuckets()
            buckets[kind] = created
            kindBucket = created
        }
        kindBucket.add(prefix: prefix, sample: sample)
    }
}

