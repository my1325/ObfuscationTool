import Foundation
import PathKit

public struct PathTransformer: Sendable {
    public init() {}

    public func transform(
        _ path: Path,
        rules: [Rule]
    ) -> Path {
        let active = rules.filter { $0.enabled && $0.appliesTo.contains(.path) }
        guard !active.isEmpty else { return path }

        var components = path.components
        for rule in active {
            if rule.scope.onlyFilename, let last = components.last {
                components[components.count - 1] = apply(rule, to: last)
            } else {
                components = components.map { apply(rule, to: $0) }
            }
        }
        return Path(components: components)
    }

    private func apply(_ rule: Rule, to value: String) -> String {
        switch rule.kind {
        case let .replace(map):
            return map
                .keys
                .sorted { $0.count > $1.count }
                .reduce(value) { current, key in
                    let replaceValue = map[key] ?? ""
                    return replaceString(
                        current,
                        key: key,
                        value: replaceValue,
                        onlyPrefix: rule.scope.onlyPrefix
                    )
                }

        case let .caseConvert(prefix, toLowercase, direction):
            switch direction {
            case .camelToSnake:
                return camelToSnake(value, prefix: prefix, toLowercase: toLowercase)
            case .snakeToCamel:
                return snakeToCamel(value, prefix: prefix, toLowercase: toLowercase)
            }

        case .shuffle:
            return value
        }
    }

    private func replaceString(
        _ origin: String,
        key: String,
        value: String,
        onlyPrefix: Bool
    ) -> String {
        if !onlyPrefix {
            return origin.replacingOccurrences(of: key, with: value)
        }
        guard origin.hasPrefix(key), let range = origin.range(of: key) else { return origin }
        return origin.replacingCharacters(in: range, with: value)
    }

    private func camelToSnake(
        _ value: String,
        prefix: String,
        toLowercase: Bool
    ) -> String {
        guard value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(prefix) else { return value }
        let replaced = value.replacingOccurrences(of: prefix, with: "_PREFIX_")
        let withUnderscore = replaced.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1_$2",
            options: .regularExpression
        )
        if toLowercase {
            return withUnderscore.lowercased().replacingOccurrences(of: "_prefix_", with: prefix)
        }
        return withUnderscore.capitalized.replacingOccurrences(of: "_Prefix_", with: prefix)
    }

    private func snakeToCamel(
        _ value: String,
        prefix: String,
        toLowercase: Bool
    ) -> String {
        guard value.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(prefix) else { return value }
        if value.count(where: { $0 == "_" }) <= 1 { return value }

        let replaced = value.replacingOccurrences(of: prefix, with: "PREFIX_")
        var parts = replaced.components(separatedBy: "_")
        let first = toLowercase ? 2 : 1
        if parts.count > first {
            for i in first..<parts.count {
                guard !parts[i].isEmpty else { continue }
                parts[i] = parts[i].prefix(1).uppercased() + parts[i].dropFirst()
            }
        }
        return parts.joined().replacingOccurrences(of: "PREFIX", with: prefix)
    }
}

