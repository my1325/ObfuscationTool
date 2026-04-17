import Foundation

public enum RuleTarget: String, Codable, CaseIterable, Hashable, Sendable {
    case path
    case content
    case swiftStructure
}

public struct RuleScope: Codable, Hashable, Sendable {
    public var onlyPrefix: Bool
    public var onlyFilename: Bool

    public init(onlyPrefix: Bool = false, onlyFilename: Bool = false) {
        self.onlyPrefix = onlyPrefix
        self.onlyFilename = onlyFilename
    }
}

public enum CaseConvertDirection: String, Codable, Hashable, Sendable, CaseIterable {
    case camelToSnake
    case snakeToCamel
}

public enum RuleKind: Hashable, Sendable, Codable {
    case replace(map: [String: String])
    case caseConvert(prefix: String, toLowercase: Bool, direction: CaseConvertDirection)
    case shuffle(orderAware: Bool)

    private enum CodingKeys: String, CodingKey {
        case replace
        case camelToSnake
        case snakeToCamel
        case shuffle
    }

    private struct ReplacePayload: Codable, Hashable {
        var map: [String: String]
    }

    private struct CasePayload: Codable, Hashable {
        var prefix: String
        var toLowercase: Bool
    }

    private struct ShufflePayload: Codable, Hashable {
        var orderAware: Bool
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.replace) {
            let payload = try container.decode(ReplacePayload.self, forKey: .replace)
            self = .replace(map: payload.map)
            return
        }

        // 兼容旧 JSON：camelToSnake / snakeToCamel 两种 case
        if container.contains(.camelToSnake) {
            let payload = try container.decode(CasePayload.self, forKey: .camelToSnake)
            self = .caseConvert(prefix: payload.prefix, toLowercase: payload.toLowercase, direction: .camelToSnake)
            return
        }

        if container.contains(.snakeToCamel) {
            let payload = try container.decode(CasePayload.self, forKey: .snakeToCamel)
            self = .caseConvert(prefix: payload.prefix, toLowercase: payload.toLowercase, direction: .snakeToCamel)
            return
        }

        if container.contains(.shuffle) {
            let payload = try container.decode(ShufflePayload.self, forKey: .shuffle)
            self = .shuffle(orderAware: payload.orderAware)
            return
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown RuleKind payload"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .replace(map):
            try container.encode(ReplacePayload(map: map), forKey: .replace)
        case let .caseConvert(prefix, toLowercase, direction):
            let payload = CasePayload(prefix: prefix, toLowercase: toLowercase)
            // 保持兼容输出：仍按旧字段名输出
            switch direction {
            case .camelToSnake:
                try container.encode(payload, forKey: .camelToSnake)
            case .snakeToCamel:
                try container.encode(payload, forKey: .snakeToCamel)
            }
        case let .shuffle(orderAware):
            try container.encode(ShufflePayload(orderAware: orderAware), forKey: .shuffle)
        }
    }
}

public struct Rule: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var enabled: Bool
    public var appliesTo: Set<RuleTarget>
    public var scope: RuleScope
    public var kind: RuleKind

    public init(
        id: UUID = UUID(),
        enabled: Bool = true,
        appliesTo: Set<RuleTarget>,
        scope: RuleScope = .init(),
        kind: RuleKind
    ) {
        self.id = id
        self.enabled = enabled
        self.appliesTo = appliesTo
        self.scope = scope
        self.kind = kind
    }
}

public struct ProjectConfig: Codable, Hashable, Sendable {
    public var input: String
    public var output: String
    public var keepDirectory: Bool
    public var rules: [Rule]

    public init(
        input: String,
        output: String,
        keepDirectory: Bool = false,
        rules: [Rule] = []
    ) {
        self.input = input
        self.output = output
        self.keepDirectory = keepDirectory
        self.rules = rules
    }
}

public enum ConfigIO {
    public static func load(from url: URL) throws -> ProjectConfig {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ProjectConfig.self, from: data)
    }

    public static func save(_ config: ProjectConfig, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: url, options: [.atomic])
    }
}

