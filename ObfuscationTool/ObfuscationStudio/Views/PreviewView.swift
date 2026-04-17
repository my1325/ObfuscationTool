import SwiftUI
import UniformTypeIdentifiers

struct PreviewView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("选择文件路径（UTF-8 文本）", text: $model.previewFilePath)
                Button("选择…") { pickFile { model.previewFilePath = $0 } }
                Button("刷新") { model.refreshPreview() }
            }
            .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                loadFirstFileURL(providers) { url in
                    model.previewFilePath = url.path
                    model.refreshPreview()
                }
            }

            if let err = model.previewError {
                Text(err)
                    .foregroundColor(.red)
            }

            HSplitView {
                VStack(alignment: .leading) {
                    Text("Before").font(.headline)
                    ScrollView {
                        Text(model.previewBefore)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }

                VStack(alignment: .leading) {
                    Text("After").font(.headline)
                    ScrollView {
                        Text(model.previewAfter)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .padding()
    }

    private func pickFile(onPick: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { resp in
            guard resp == .OK, let url = panel.url else { return }
            onPick(url.path)
        }
    }

    private func loadFirstFileURL(
        _ providers: [NSItemProvider],
        onPick: @escaping (URL) -> Void
    ) -> Bool {
        guard let p = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }
        p.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }
            DispatchQueue.main.async { onPick(url) }
        }
        return true
    }
}

