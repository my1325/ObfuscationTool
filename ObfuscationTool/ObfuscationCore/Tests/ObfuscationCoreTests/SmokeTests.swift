import XCTest
import PathKit
@testable import ObfuscationCore

final class SmokeTests: XCTestCase {
    func testPathOnlyFilenameScopeDoesNotAffectDirectories() {
        let transformer = PathTransformer()
        let rules: [Rule] = [
            .init(
                appliesTo: [.path],
                scope: .init(onlyPrefix: true, onlyFilename: true),
                kind: .replace(map: ["BF_": "ZZ_"])
            ),
        ]

        let input = Path("/A/BF_Folder/BF_File.swift")
        let out = transformer.transform(input, rules: rules)
        XCTAssertEqual(out.string, "/A/BF_Folder/ZZ_File.swift")
    }

    /// xcassets 内相对路径多段时，路径规则应作用到 imageset 等目录名（需非 onlyFilename 限制整条路径末段）。
    func testAssetCatalogInnerPathTransformsImagesetFolder() {
        let transformer = PathTransformer()
        let rules: [Rule] = [
            .init(
                appliesTo: [.path],
                scope: .init(onlyPrefix: true, onlyFilename: false),
                kind: .replace(map: ["BF_": "ZZ_"])
            ),
        ]
        let inner = Path("Tab/BF_Home.imageset/Contents.json")
        let out = transformer.transform(inner, rules: rules)
        XCTAssertTrue(out.string.contains("ZZ_Home.imageset"), "got: \(out.string)")
    }

    func testOCSkipsCommentsAndStrings() throws {
        let processor = ContentProcessor()
        let rules: [Rule] = [
            .init(
                appliesTo: [.content],
                scope: .init(onlyPrefix: true, onlyFilename: false),
                kind: .replace(map: ["BF_": "ZZ_"])
            ),
        ]

        let source = """
        // BF_HelloWorld should stay
        static NSString * const BF_HelloWorld = @\"BF_HelloWorld\";
        """
        let data = source.data(using: .utf8)!
        let out = try processor.process(path: .init("/tmp/Test.m"), data: data, rules: rules)
        let s = String(data: out, encoding: .utf8)!

        // comment should remain, string literal should remain
        XCTAssertTrue(s.contains("// BF_HelloWorld should stay"))
        XCTAssertTrue(s.contains("@\"BF_HelloWorld\""))
        // identifier should change
        XCTAssertTrue(s.contains("ZZ_HelloWorld"))
    }
}

