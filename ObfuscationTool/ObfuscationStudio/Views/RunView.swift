import SwiftUI

struct RunView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(model.isRunning ? "运行中…" : "开始运行") {
                    model.runBatch()
                }
                .disabled(model.isRunning)

                Button("取消") {
                    model.cancelRun()
                }
                .disabled(!model.isRunning)

                Spacer()
                Text(model.progressText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(model.logLines.indices, id: \.self) { index in
                        Text(model.logLines[index])
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding()
    }
}

