import SwiftUI

enum StudioWindow {
    /// 内容区域固定尺寸，不含标题栏。
    static let contentSize = NSSize(width: 640, height: 420)
}

@main
struct ObfuscationStudioApp: App {
    @StateObject private var model = StudioModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(
                    minWidth: StudioWindow.contentSize.width,
                    maxWidth: StudioWindow.contentSize.width,
                    minHeight: StudioWindow.contentSize.height,
                    maxHeight: StudioWindow.contentSize.height
                )
                .fixedSize()
                .background(WindowSizeLock())
        }
        .defaultSize(width: StudioWindow.contentSize.width, height: StudioWindow.contentSize.height)
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

/// 窗口真正的尺寸在 NSWindow 上。SwiftUI 的 frame 只约束内容视图，盖不住已经记住的窗口帧。
private struct WindowSizeLock: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowLockView {
        WindowLockView()
    }

    func updateNSView(_ nsView: WindowLockView, context: Context) {
        nsView.lockIfPossible()
    }
}

private final class WindowLockView: NSView {
    private var resizeToken: NSObjectProtocol?
    private var applying = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let resizeToken {
            NotificationCenter.default.removeObserver(resizeToken)
            self.resizeToken = nil
        }
        guard let window else { return }
        lock(window)
        resizeToken = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] note in
            guard let self, let window = note.object as? NSWindow else { return }
            self.lock(window)
        }
    }

    func lockIfPossible() {
        guard let window else { return }
        lock(window)
    }

    deinit {
        if let resizeToken {
            NotificationCenter.default.removeObserver(resizeToken)
        }
    }

    private func lock(_ window: NSWindow) {
        guard !applying else { return }
        applying = true
        defer { applying = false }

        let content = StudioWindow.contentSize
        window.styleMask.remove(.resizable)
        window.isRestorable = false
        _ = window.setFrameAutosaveName("")
        window.standardWindowButton(.zoomButton)?.isEnabled = false

        let already = nearly(window.contentView?.bounds.size, content)
            && nearly(window.contentMinSize, content)
            && nearly(window.contentMaxSize, content)
        if !already {
            // 先放下限，否则 setContentSize 会被原来更大的 contentMinSize 夹住。
            window.contentMinSize = content
            window.contentMaxSize = content
            window.minSize = NSSize(width: 1, height: 1)
            window.maxSize = NSSize(width: 10_000, height: 10_000)
            window.setContentSize(content)
        }
        let frame = window.frame.size
        if !nearly(window.minSize, frame) { window.minSize = frame }
        if !nearly(window.maxSize, frame) { window.maxSize = frame }
        if !nearly(window.contentMinSize, content) { window.contentMinSize = content }
        if !nearly(window.contentMaxSize, content) { window.contentMaxSize = content }
    }

    private func nearly(_ size: NSSize?, _ other: NSSize) -> Bool {
        guard let size else { return false }
        return abs(size.width - other.width) < 1 && abs(size.height - other.height) < 1
    }
}
