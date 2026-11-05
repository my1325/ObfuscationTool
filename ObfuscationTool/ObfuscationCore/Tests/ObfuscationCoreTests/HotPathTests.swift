import XCTest
import Foundation
import PathKit
@testable import ObfuscationCore

private final class RunBox: @unchecked Sendable {
    var summary = RunSummary()
    var failures: [String] = []
}

final class HotPathTests: XCTestCase {
    func testLongestReplacementKeyWinsAndOnlyPrefixStaysAnchored() {
        let transformer = PathTransformer()
        let rules: [Rule] = [
            .init(
                appliesTo: [.path],
                scope: .init(onlyPrefix: true, onlyFilename: false),
                kind: .replace(map: ["BF_": "ZZ_", "BF_Long_": "QQ_"])
            ),
        ]

        XCTAssertEqual(
            transformer.transform(Path("BF_Long_Name"), rules: rules).string,
            "QQ_Name"
        )
        XCTAssertEqual(
            transformer.transform(Path("/tmp/BF_Bar.swift"), rules: rules).string,
            "/tmp/ZZ_Bar.swift"
        )
        XCTAssertEqual(
            transformer.transform(Path("/tmp/FooBF_Bar.swift"), rules: rules).string,
            "/tmp/FooBF_Bar.swift"
        )
    }

    func testCaseConvertRewritesEveryPathComponent() {
        let transformer = PathTransformer()
        let rules: [Rule] = [
            .init(
                appliesTo: [.path],
                kind: .caseConvert(prefix: "BF_", toLowercase: true, direction: .camelToSnake)
            ),
        ]

        XCTAssertEqual(
            transformer.transform(Path("BF_Folder/BF_fooBar"), rules: rules).string,
            "BF_folder/BF_foo_bar"
        )
        XCTAssertEqual(
            transformer.transform(Path("/tmp/ BF_fooBar"), rules: rules).string,
            "/tmp/ BF_foo_bar"
        )

        let upper: [Rule] = [
            .init(
                appliesTo: [.path],
                kind: .caseConvert(prefix: "BF_", toLowercase: false, direction: .camelToSnake)
            ),
        ]
        XCTAssertEqual(
            transformer.transform(Path("BF_fooBar"), rules: upper).string,
            "BF_Foo_Bar"
        )

        let snake: [Rule] = [
            .init(
                appliesTo: [.path],
                kind: .caseConvert(prefix: "BF_", toLowercase: true, direction: .snakeToCamel)
            ),
        ]
        XCTAssertEqual(
            transformer.transform(Path("BF_foo_bar"), rules: snake).string,
            "BF_fooBar"
        )

        let shuffleOnly: [Rule] = [
            .init(appliesTo: [.path], kind: .shuffle(orderAware: true)),
        ]
        XCTAssertEqual(
            transformer.transform(Path("BF_Folder/BF_fooBar"), rules: shuffleOnly).string,
            "BF_Folder/BF_fooBar"
        )
    }

    func testObjectiveCCaseConvertSkipsCommentsAndStrings() throws {
        let processor = ContentProcessor()
        let rules: [Rule] = [
            .init(
                appliesTo: [.content],
                kind: .caseConvert(prefix: "BF_", toLowercase: true, direction: .camelToSnake)
            ),
        ]
        let source = """
        // BF_fooBar should stay
        static int BF_fooBar = 1;
        static NSString *s = @\"BF_fooBar\";
        """
        let out = try processor.process(path: .init("/tmp/Test.m"), data: Data(source.utf8), rules: rules)
        let text = String(decoding: out, as: UTF8.self)
        XCTAssertTrue(text.contains("// BF_fooBar should stay"))
        XCTAssertTrue(text.contains("@\"BF_fooBar\""))
        XCTAssertTrue(text.contains("static int BF_foo_bar = 1;"))
    }

    func testPlainJSONIsUntouchedUnlessItIsAssetCatalogContents() throws {
        let processor = ContentProcessor()
        let rules: [Rule] = [
            .init(
                appliesTo: [.content, .path],
                scope: .init(onlyPrefix: false, onlyFilename: false),
                kind: .replace(map: ["BF_": "ZZ_"])
            ),
        ]
        let data = Data(#"{"name":"BF_Icon"}"#.utf8)

        let plain = try processor.process(path: .init("/tmp/Info.json"), data: data, rules: rules)
        XCTAssertEqual(plain, data)

        let catalog = try processor.process(
            path: .init("/tmp/Assets.xcassets/BF_Icon.imageset/Contents.json"),
            data: data,
            rules: rules
        )
        XCTAssertEqual(String(decoding: catalog, as: UTF8.self), #"{"name":"ZZ_Icon"}"#)
    }

    func testMayRewriteContentMatchesTheProcessorSwitch() {
        let processor = ContentProcessor()
        let contentReplace: [Rule] = [
            .init(appliesTo: [.content], kind: .replace(map: ["BF_": "ZZ_"])),
        ]
        let pathOnly: [Rule] = [
            .init(appliesTo: [.path], kind: .replace(map: ["BF_": "ZZ_"])),
        ]
        let emptyMap: [Rule] = [
            .init(appliesTo: [.content], kind: .replace(map: [:])),
        ]

        XCTAssertTrue(processor.mayRewriteContent(path: .init("/tmp/A.swift"), rules: []))
        XCTAssertTrue(processor.mayRewriteContent(path: .init("/tmp/Localizable.strings"), rules: []))
        XCTAssertTrue(processor.mayRewriteContent(
            path: .init("/tmp/Assets.xcassets/AppIcon.appiconset/Contents.json"),
            rules: []
        ))
        XCTAssertFalse(processor.mayRewriteContent(path: .init("/tmp/Info.json"), rules: contentReplace))
        XCTAssertFalse(processor.mayRewriteContent(path: .init("/tmp/Icon.png"), rules: contentReplace))
        XCTAssertTrue(processor.mayRewriteContent(path: .init("/tmp/A.m"), rules: contentReplace))
        XCTAssertFalse(processor.mayRewriteContent(path: .init("/tmp/A.m"), rules: pathOnly))
        XCTAssertFalse(processor.mayRewriteContent(path: .init("/tmp/A.h"), rules: emptyMap))
    }

    func testHiddenComponentCheckMatchesPathPieces() {
        XCTAssertTrue(TreeEnumeration.containsHiddenComponent(".git"))
        XCTAssertTrue(TreeEnumeration.containsHiddenComponent("Src/.git/config"))
        XCTAssertFalse(TreeEnumeration.containsHiddenComponent("Src/File.swift"))
        XCTAssertFalse(TreeEnumeration.containsHiddenComponent("Src/File.swift.bak"))
    }

    func testPrefixScanCountsHitsAndSkipsHiddenFiles() throws {
        let root = try makeTempDirectory()
        defer { remove(root) }

        let visible = """
        class BF_Model {}
        class BF_Other {}
        class ZZ_Skip {}
        struct BF_Box {}
        enum BF_Kind {}
        protocol BF_Providing {}
        let BF_value = 1
        \( (0..<12).map { "func BF_f\($0)() {}" }.joined(separator: "\n") )
        """
        try write(visible, to: root + "Visible.swift")
        try (root + ".hidden").mkpath()
        try write("class BF_Secret {}\n", to: root + ".hidden" + "Secret.swift")

        let rules: [Rule] = [
            .init(enabled: false, appliesTo: [.content], kind: .replace(map: ["BF_": "NO_"])),
            .init(enabled: true, appliesTo: [.content], kind: .replace(map: ["ZZ_": "AA_"])),
        ]
        let result = PrefixScanner().scan(inputRoot: root, rules: rules)

        XCTAssertEqual(result.officialPrefixes, ["ZZ_"])
        let classes = try XCTUnwrap(result.hitsByKind[.typeClass]).first { $0.prefix == "BF_" }
        XCTAssertEqual(classes?.count, 2)
        XCTAssertEqual(classes?.samples, ["BF_Model", "BF_Other"])
        XCTAssertFalse(result.hitsByKind.values.joined().contains { $0.samples.contains("BF_Secret") || $0.samples.contains("ZZ_Skip") })

        XCTAssertEqual(result.hitsByKind[.typeStruct]?.first?.prefix, "BF_")
        XCTAssertEqual(result.hitsByKind[.typeEnum]?.first?.samples, ["BF_Kind"])
        XCTAssertEqual(result.hitsByKind[.typeProtocol]?.first?.samples, ["BF_Providing"])
        XCTAssertEqual(result.hitsByKind[.variable]?.first?.samples, ["BF_value"])

        let functions = try XCTUnwrap(result.hitsByKind[.function]?.first)
        XCTAssertEqual(functions.prefix, "BF_")
        XCTAssertEqual(functions.count, 12)
        XCTAssertEqual(functions.samples.count, 10)
        XCTAssertEqual(functions.samples.first, "BF_f0")
        XCTAssertEqual(functions.samples.last, "BF_f9")

        let cancelled = PrefixScanner().scan(inputRoot: root, rules: rules) { true }
        XCTAssertEqual(cancelled.hitsByKind[.typeClass] ?? [], [])
        XCTAssertEqual(cancelled.officialPrefixes, ["ZZ_"])
    }

    func testRunSkipsHiddenCopiesBundlesAndRenames() throws {
        let root = try makeTempDirectory()
        defer { remove(root) }
        let input = root + "in"
        let output = root + "out"
        try input.mkpath()
        try write("hello", to: input + "BF_note.txt")
        try write("plain", to: input + "plain.txt")
        try (input + ".hidden").mkpath()
        try write("nope", to: input + ".hidden" + "BF_secret.txt")
        try (input + "Pack.bundle").mkpath()
        try write("inner", to: input + "Pack.bundle" + "BF_inner.txt")
        try write("class BF_Model {}\n", to: input + "Sample.swift")
        try write("static int BF_fooBar = 1;\n", to: input + "Sample.m")

        let config = ProjectConfig(
            input: input.string,
            output: output.string,
            keepDirectory: true,
            rules: [
                .init(
                    appliesTo: [.path, .content],
                    scope: .init(onlyPrefix: true, onlyFilename: false),
                    kind: .replace(map: ["BF_": "ZZ_"])
                ),
            ]
        )

        let summary = try run(config)
        XCTAssertEqual(summary.errors, 0)
        XCTAssertEqual(try (output + "ZZ_note.txt").read(.utf8), "hello")
        XCTAssertEqual(try (output + "plain.txt").read(.utf8), "plain")
        XCTAssertFalse((output + ".hidden").exists)
        XCTAssertFalse((output + "ZZ_secret.txt").exists)
        XCTAssertEqual(try (output + "Pack.bundle" + "BF_inner.txt").read(.utf8), "inner")
        XCTAssertFalse((output + "ZZ_inner.txt").exists)

        let swift = try (output + "Sample.swift").read(.utf8)
        XCTAssertTrue(swift.contains("ZZ_Model"), swift)
        XCTAssertFalse(swift.contains("BF_Model"), swift)
        XCTAssertEqual(try (output + "Sample.m").read(.utf8), "static int ZZ_fooBar = 1;\n")
    }

    func testInPlaceRunLeavesUnchangedBinariesAndStillRewritesSwift() throws {
        let root = try makeTempDirectory()
        defer { remove(root) }
        try write("hello", to: root + "plain.txt")
        try write("class BF_Model {}\n", to: root + "Sample.swift")
        let binary = Data([0, 1, 2, 255, 10])
        try (root + "pic.bin").write(binary)

        let config = ProjectConfig(
            input: root.string,
            output: root.string,
            keepDirectory: true,
            rules: [
                .init(
                    appliesTo: [.path, .content],
                    scope: .init(onlyPrefix: true, onlyFilename: false),
                    kind: .replace(map: ["BF_": "ZZ_"])
                ),
            ]
        )
        let summary = try run(config)
        XCTAssertEqual(summary.errors, 0)
        XCTAssertEqual(try (root + "plain.txt").read(.utf8), "hello")
        let saved: Data = try (root + "pic.bin").read()
        XCTAssertEqual(saved, binary)
        let swift = try (root + "Sample.swift").read(.utf8)
        XCTAssertTrue(swift.contains("ZZ_Model"), swift)
    }

    func testCaseConvertStageRenamesWithoutRewritingPlainText() throws {
        let root = try makeTempDirectory()
        defer { remove(root) }
        let input = root + "in"
        let output = root + "out"
        try input.mkpath()
        try write("keep", to: input + "BF_fooBar.txt")

        let config = ProjectConfig(
            input: input.string,
            output: output.string,
            keepDirectory: false,
            rules: [
                .init(
                    appliesTo: [.path, .content],
                    kind: .caseConvert(prefix: "BF_", toLowercase: true, direction: .camelToSnake)
                ),
            ]
        )
        let summary = try run(config)
        XCTAssertEqual(summary.errors, 0)
        XCTAssertEqual(try (output + "BF_foo_bar.txt").read(.utf8), "keep")
        XCTAssertFalse((output + "BF_fooBar.txt").exists)
    }

    private func run(_ config: ProjectConfig) throws -> RunSummary {
        let runner = Runner()
        let box = RunBox()
        runner.run(config: config) { event in
            switch event {
            case let .didFinish(value):
                box.summary = value
            case let .didFail(path, message):
                box.failures.append("\(path): \(message)")
            default:
                break
            }
        }
        if !box.failures.isEmpty {
            XCTFail(box.failures.joined(separator: "\n"))
        }
        return box.summary
    }

    private func makeTempDirectory() throws -> Path {
        let dir = Path(FileManager.default.temporaryDirectory.path) + "obf-\(UUID().uuidString)"
        try dir.mkpath()
        return dir
    }

    private func write(_ text: String, to path: Path) throws {
        try path.parent().mkpath()
        try path.write(text)
    }

    private func remove(_ path: Path) {
        try? FileManager.default.removeItem(atPath: path.string)
    }
}
