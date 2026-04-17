import SwiftUI
import UniformTypeIdentifiers

struct ConfigView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        Form {
            HStack {
                TextField("Input 路径（拖拽文件夹也可以）", text: $model.config.input)
                Button("选择…") { pickDirectory { model.config.input = $0 } }
            }
            .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                loadFirstFileURL(providers) { url in
                    model.config.input = url.path
                }
            }

            HStack {
                TextField("Output 路径（拖拽文件夹也可以）", text: $model.config.output)
                Button("选择…") { pickDirectory { model.config.output = $0 } }
            }
            .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
                loadFirstFileURL(providers) { url in
                    model.config.output = url.path
                }
            }
            Toggle("保持目录结构（keepDirectory）", isOn: $model.config.keepDirectory)
        }
        .padding()
    }

    private func pickDirectory(onPick: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
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

