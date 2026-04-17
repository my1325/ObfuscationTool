import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        NavigationSplitView {
            List(selection: $model.sidebarSelection) {
                Text("配置").tag(SidebarSelection.config)
                Text("规则").tag(SidebarSelection.rules)
                Text("前缀扫描").tag(SidebarSelection.prefixScan)
                Text("预览").tag(SidebarSelection.preview)
                Text("运行").tag(SidebarSelection.run)
            }
            .frame(minWidth: 180)
        } detail: {
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
        .navigationTitle(model.windowTitle)
    }
}

#Preview {
    ContentView()
        .environmentObject(StudioModel())
}

