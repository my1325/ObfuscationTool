import Foundation

/// 路径和标识符共用的文本替换。调用方按 key 从长到短应用。
/// 驼峰边界正则只编译一次。
enum TextRewriter {
    private static let trimSet = CharacterSet.whitespacesAndNewlines

    private static let camelBoundary: NSRegularExpression = {
        // 与 String.replacingOccurrences(..., options: .regularExpression) 使用同一模式。
        try! NSRegularExpression(pattern: "([a-z])([A-Z])", options: [])
    }()

    static func replacing(_ origin: String, key: String, value: String, onlyPrefix: Bool) -> String {
        if !onlyPrefix {
            return origin.replacingOccurrences(of: key, with: value)
        }
        // hasPrefix 之后再 range(of:) 会把 key 再扫一遍。前缀命中时第一次出现就是开头。
        guard origin.hasPrefix(key) else { return origin }
        return value + origin.dropFirst(key.count)
    }

    static func camelToSnake(_ value: String, prefix: String, toLowercase: Bool) -> String {
        guard hasTrimmedPrefix(value, prefix: prefix) else { return value }
        let replaced = value.replacingOccurrences(of: prefix, with: "_PREFIX_")
        let withUnderscore = applyCamelBoundary(replaced)
        if toLowercase {
            return withUnderscore.lowercased().replacingOccurrences(of: "_prefix_", with: prefix)
        }
        return withUnderscore.capitalized.replacingOccurrences(of: "_Prefix_", with: prefix)
    }

    static func snakeToCamel(_ value: String, prefix: String, toLowercase: Bool) -> String {
        guard hasTrimmedPrefix(value, prefix: prefix) else { return value }
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

    private static func applyCamelBoundary(_ value: String) -> String {
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return camelBoundary.stringByReplacingMatches(
            in: value,
            options: [],
            range: range,
            withTemplate: "$1_$2"
        )
    }

    /// 对齐 trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix。
    /// 没有首尾空白时不再分配裁剪后的字符串。
    private static func hasTrimmedPrefix(_ value: String, prefix: String) -> Bool {
        if value.hasPrefix(prefix) { return true }
        let scalars = value.unicodeScalars
        guard let first = scalars.first, let last = scalars.last else { return false }
        guard trimSet.contains(first) || trimSet.contains(last) else { return false }
        return value.trimmingCharacters(in: trimSet).hasPrefix(prefix)
    }
}
