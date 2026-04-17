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
            }
        }
    }
}

