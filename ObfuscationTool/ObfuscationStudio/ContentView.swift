import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        NavigationSplitView {
            List(selection: $model.sidebarSelection) {
                Section("准备") {
                    sidebarRow(.config, title: "路径", symbol: "folder")
                    sidebarRow(.rules, title: "规则", symbol: "list.bullet")
                }
                Section("检查") {
                    sidebarRow(.prefixScan, title: "前缀", symbol: "text.magnifyingglass")
                    sidebarRow(.preview, title: "预览", symbol: "doc.text.magnifyingglass")
                }
                Section("执行") {
                    sidebarRow(.run, title: "运行", symbol: "play.fill")
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if let banner = model.bannerMessage {
                        Text(banner)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .controlBackgroundColor))
                    }
                }
        }
        .navigationTitle(model.windowTitle)
        .toolbar {
            ToolbarItemGroup {
                Button("打开配置") { model.presentOpenPanel() }
                Button("保存配置") { model.saveConfigInteractively() }
            }
            ToolbarItemGroup {
                if model.isRunning {
                    Button("取消") { model.cancelRun() }
                } else {
                    Button("运行") {
                        model.sidebarSelection = .run
                        model.runBatch()
                    }
                    .disabled(model.config.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .help(model.config.input.isEmpty ? "先选择源目录" : "按当前规则写出结果")
                }
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch model.sidebarSelection {
        case .config:
            ConfigView()
        case .rules:
            RulesView()
        case .prefixScan:
            PrefixScanView()
        case .preview:
            PreviewView()
        case .run:
            RunView()
        }
    }

    private func sidebarRow(_ selection: SidebarSelection, title: String, symbol: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(sidebarDetail(selection))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: symbol)
        }
        .tag(selection)
    }

    private func sidebarDetail(_ selection: SidebarSelection) -> String {
        switch selection {
        case .config:
            return model.config.input.isEmpty
                ? "未选择源目录"
                : (model.config.input as NSString).lastPathComponent
        case .rules:
            let enabled = model.config.rules.filter(\.enabled).count
            if model.config.rules.isEmpty { return "还没有规则" }
            return "\(enabled) 条启用"
        case .prefixScan:
            if model.prefixScanIsRunning { return "扫描中" }
            if model.prefixScanResult == nil { return "未扫描" }
            return "\(model.uncoveredPrefixCount) 个未覆盖"
        case .preview:
            return model.previewFilePath.isEmpty
                ? "未选择文件"
                : (model.previewFilePath as NSString).lastPathComponent
        case .run:
            if model.isRunning { return model.progressText.isEmpty ? "运行中" : model.progressText }
            if let summary = model.lastRunSummary {
                return summary.errors == 0 ? "完成" : "\(summary.errors) 个错误"
            }
            return "未运行"
        }
    }
}

struct PathField: View {
    var placeholder: String
    @Binding var path: String
    var canChooseDirectories: Bool
    var canChooseFiles: Bool
    var onPicked: ((String) -> Void)? = nil

    var body: some View {
        HStack {
            TextField(placeholder, text: $path)
            Button("选择…") { pick() }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            loadFirstFileURL(providers) { url in
                path = url.path
                onPicked?(url.path)
            }
        }
    }

    private func pick() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = canChooseDirectories
        panel.canChooseFiles = canChooseFiles
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            DispatchQueue.main.async {
                path = url.path
                onPicked?(url.path)
            }
        }
    }

    private func loadFirstFileURL(
        _ providers: [NSItemProvider],
        onPick: @escaping (URL) -> Void
    ) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }
            DispatchQueue.main.async { onPick(url) }
        }
        return true
    }
}

#Preview {
    ContentView()
        .environmentObject(StudioModel())
}
