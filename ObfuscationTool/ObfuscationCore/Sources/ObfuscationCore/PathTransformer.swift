import Foundation
import PathKit

public struct PathTransformer: Sendable {
    public init() {}

    public func transform(
        _ path: Path,
        rules: [Rule]
    ) -> Path {
        let active = compile(rules)
        guard !active.isEmpty else { return path }

        var components = path.components
        for rule in active {
            if rule.onlyFilename, let last = components.last {
                components[components.count - 1] = apply(rule.kind, to: last)
            } else {
                for index in components.indices {
                    components[index] = apply(rule.kind, to: components[index])
                }
            }
        }
        return Path(components: components)
    }

    private struct CompiledRule {
        var onlyFilename: Bool
        var kind: Kind
    }

    private enum Kind {
        case replace(pairs: [(key: String, value: String)], onlyPrefix: Bool)
        case camelToSnake(prefix: String, toLowercase: Bool)
        case snakeToCamel(prefix: String, toLowercase: Bool)
    }

    /// 每个路径只把替换 key 排序一次，而不是每个路径组件都排序。
    private func compile(_ rules: [Rule]) -> [CompiledRule] {
        var compiled: [CompiledRule] = []
        compiled.reserveCapacity(rules.count)
        for rule in rules where rule.enabled && rule.appliesTo.contains(.path) {
            let kind: Kind
            switch rule.kind {
            case let .replace(map):
                let pairs = map.keys.sorted { $0.count > $1.count }.map { key in
                    (key: key, value: map[key] ?? "")
                }
                kind = .replace(pairs: pairs, onlyPrefix: rule.scope.onlyPrefix)
            case let .caseConvert(prefix, toLowercase, direction):
                switch direction {
                case .camelToSnake:
                    kind = .camelToSnake(prefix: prefix, toLowercase: toLowercase)
                case .snakeToCamel:
                    kind = .snakeToCamel(prefix: prefix, toLowercase: toLowercase)
                }
            case .shuffle:
                continue
            }
            compiled.append(CompiledRule(onlyFilename: rule.scope.onlyFilename, kind: kind))
        }
        return compiled
    }

    private func apply(_ kind: Kind, to value: String) -> String {
        switch kind {
        case let .replace(pairs, onlyPrefix):
            return pairs.reduce(value) { current, pair in
                TextRewriter.replacing(current, key: pair.key, value: pair.value, onlyPrefix: onlyPrefix)
            }
        case let .camelToSnake(prefix, toLowercase):
            return TextRewriter.camelToSnake(value, prefix: prefix, toLowercase: toLowercase)
        case let .snakeToCamel(prefix, toLowercase):
            return TextRewriter.snakeToCamel(value, prefix: prefix, toLowercase: toLowercase)
        }
    }
}
