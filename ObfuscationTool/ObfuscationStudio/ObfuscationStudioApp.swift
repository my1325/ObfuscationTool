import SwiftUI

@main
struct ObfuscationStudioApp: App {
    @StateObject private var model = StudioModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
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

