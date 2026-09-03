import Foundation
import ObfuscationCore

struct PrefixScanJSON: Encodable {
    struct Hit: Encodable {
        let prefix: String
        let count: Int
        let samples: [String]
    }

    let officialPrefixes: [String]
    let hitsByKind: [String: [Hit]]

    init(_ result: PrefixScanResult) {
        officialPrefixes = result.officialPrefixes.sorted()
        hitsByKind = Dictionary(
            uniqueKeysWithValues: result.hitsByKind.map { kind, hits in
                (
                    kind.rawValue,
                    hits.map { Hit(prefix: $0.prefix, count: $0.count, samples: $0.samples) }
                )
            }
        )
    }
}

func encodePrefixScan(_ result: PrefixScanResult) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(PrefixScanJSON(result))
    guard let text = String(data: data, encoding: .utf8) else {
        throw ObfuscationError.outputIsNotValid("failed to encode scan result")
    }
    return text
}
