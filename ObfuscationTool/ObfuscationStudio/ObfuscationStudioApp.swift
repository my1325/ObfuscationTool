import SwiftUI

enum StudioWindow {
    /// 内容区域固定尺寸。侧边栏约 230，右侧够放下规则分栏和预览对照。
    static let contentSize = NSSize(width: 960, height: 640)
}

@main
struct ObfuscationStudioApp: App {
    @StateObject private var model = StudioModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(width: StudioWindow.contentSize.width, height: StudioWindow.contentSize.height)
                .background(WindowSizeLock())
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建配置") { model.newConfig() }
                    .keyboardShortcut("n")
                Button("打开配置…") { model.presentOpenPanel() }
                    .keyboardShortcut("o")
                Button("保存配置") { model.saveConfigInteractively() }
                    .keyboardShortcut("s")
                Button("另存为…") { model.presentSavePanel() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}

/// 去掉窗口的可缩放标记，并把最小、最大尺寸钉在同一帧上。
private struct WindowSizeLock: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { lock(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { lock(nsView.window) }
    }

    private func lock(_ window: NSWindow?) {
        guard let window else { return }
        if window.styleMask.contains(.resizable) {
            window.styleMask.remove(.resizable)
        }
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        if window.contentView?.bounds.size != StudioWindow.contentSize {
            window.setContentSize(StudioWindow.contentSize)
        }
        let frame = window.frame.size
        if window.minSize != frame { window.minSize = frame }
        if window.maxSize != frame { window.maxSize = frame }
    }
}
