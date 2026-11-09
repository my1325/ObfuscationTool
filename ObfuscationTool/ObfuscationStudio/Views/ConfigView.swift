import SwiftUI

struct ConfigView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("先选定源目录和输出目录，再去写规则。")
                    .foregroundColor(.secondary)

                GroupBox("源目录") {
                    VStack(alignment: .leading, spacing: 8) {
                        PathField(
                            placeholder: "要混淆的工程或文件夹",
                            path: $model.config.input,
                            canChooseDirectories: true,
                            canChooseFiles: false
                        )
                        Text("拖入文件夹也可以。前缀扫描和运行都从这里读。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }

                GroupBox("输出目录") {
                    VStack(alignment: .leading, spacing: 8) {
                        PathField(
                            placeholder: "写出结果的文件夹",
                            path: $model.config.output,
                            canChooseDirectories: true,
                            canChooseFiles: false
                        )
                        Text("建议用另一个文件夹。和源目录相同时，运行会直接改写源文件。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }

                GroupBox("目录结构") {
                    Toggle("保留相对路径", isOn: $model.config.keepDirectory)
                        .padding(.top, 4)
                    Text("打开后，输出里仍按源目录的子文件夹摆放。关闭后，文件会平铺到输出目录。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if sameDirectory {
                    Label("输出和源是同一目录，运行会直接改写源文件。", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationSubtitle("路径")
    }

    private var sameDirectory: Bool {
        let input = standardized(model.config.input)
        let output = standardized(model.config.output)
        return !input.isEmpty && input == output
    }

    private func standardized(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return URL(fileURLWithPath: trimmed).standardizedFileURL.path
    }
}
