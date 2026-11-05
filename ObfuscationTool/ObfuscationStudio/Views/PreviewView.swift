import SwiftUI

struct PreviewView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PathField(
                placeholder: "选一个 UTF-8 文本文件，看当前规则会改成什么样",
                path: $model.previewFilePath,
                canChooseDirectories: false,
                canChooseFiles: true,
                onPicked: { _ in model.refreshPreview() }
            )
            HStack {
                Button("刷新") { model.refreshPreview() }
                    .disabled(model.previewFilePath.isEmpty)
                if unchanged {
                    Text("按当前规则，这份文件的文本没有变化。")
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            if let err = model.previewError {
                Text(err).foregroundColor(.red)
            }

            if model.previewBefore.isEmpty && model.previewAfter.isEmpty && model.previewError == nil {
                Text("预览只处理这一个文件，不会写出磁盘。")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                HSplitView {
                    previewColumn(title: "改写前", text: model.previewBefore)
                    previewColumn(title: "改写后", text: model.previewAfter)
                }
            }
        }
        .padding(20)
        .navigationSubtitle("预览")
    }

    private var unchanged: Bool {
        !model.previewBefore.isEmpty && model.previewBefore == model.previewAfter && model.previewError == nil
    }

    private func previewColumn(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ScrollView {
                Text(text.isEmpty ? " " : text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .frame(minWidth: 240)
    }
}
