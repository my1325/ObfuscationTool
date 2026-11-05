import Foundation
import PathKit

struct EnumeratedEntry {
    var path: Path
    var isDirectory: Bool
}

/// Runner 和前缀扫描共用的深度优先遍历。
/// 以 "." 开头的路径组件会被跳过，并且不再进入其子目录。
/// 每个条目只 stat 一次。Path.isDirectory / Path.isFile 各自都会标准化路径并 stat。
enum TreeEnumeration {
    static func collect(
        under root: Path,
        includeDirectories: (Path) -> Bool,
        includeFiles: (Path) -> Bool
    ) -> [EnumeratedEntry] {
        let fm = FileManager.default
        let base = root.string
        guard let enumerator = fm.enumerator(atPath: base) else { return [] }

        var entries: [EnumeratedEntry] = []
        while let rel = enumerator.nextObject() as? String {
            if rel.isEmpty { continue }
            if containsHiddenComponent(rel) {
                enumerator.skipDescendants()
                continue
            }

            let path = Path(base + "/" + rel)
            var isDirectory = ObjCBool(false)
            // 与 PathKit 一致：是否存在看的是标准化后的路径。
            guard fm.fileExists(atPath: path.normalize().string, isDirectory: &isDirectory) else {
                continue
            }

            if isDirectory.boolValue {
                if includeDirectories(path) {
                    entries.append(EnumeratedEntry(path: path, isDirectory: true))
                    enumerator.skipDescendants()
                }
                continue
            }

            if includeFiles(path) {
                entries.append(EnumeratedEntry(path: path, isDirectory: false))
            }
        }
        return entries
    }

    static func containsHiddenComponent(_ relative: String) -> Bool {
        if relative.first == "." { return true }
        var index = relative.startIndex
        while index < relative.endIndex {
            if relative[index] == "/" {
                let next = relative.index(after: index)
                if next < relative.endIndex, relative[next] == "." { return true }
            }
            index = relative.index(after: index)
        }
        return false
    }
}
