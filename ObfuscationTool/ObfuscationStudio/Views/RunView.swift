import SwiftUI

struct RunView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(headline)
                        .font(.headline)
                    Text(detail)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if model.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
                Button(model.isRunning ? "运行中…" : "开始运行") {
                    model.runBatch()
                }
                .disabled(model.isRunning || model.config.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("取消") { model.cancelRun() }
                    .disabled(!model.isRunning)
            }

            if let summary = model.lastRunSummary {
                HStack(spacing: 24) {
                    metric("处理", summary.processedFiles, emphasize: false)
                    metric("写出", summary.writtenFiles, emphasize: false)
                    metric("错误", summary.errors, emphasize: summary.errors > 0)
                }
            }

            Text("日志").font(.headline)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(model.logLines.indices, id: \.self) { index in
                            Text(model.logLines[index])
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(model.logLines[index].hasPrefix("Fail:") ? .red : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }
                }
                .onChange(of: model.logLines.count) { _ in
                    guard let last = model.logLines.indices.last else { return }
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
        .padding(20)
        .navigationSubtitle("运行")
    }

    private var headline: String {
        if model.isRunning { return "正在写出" }
        if model.lastRunSummary != nil { return "最近一次运行" }
        return "尚未运行"
    }

    private var detail: String {
        if model.isRunning {
            return model.progressText.isEmpty ? "准备文件列表…" : model.progressText
        }
        if model.config.input.isEmpty { return "先在「路径」里选择源目录。" }
        if model.config.output.isEmpty { return "还没有填写输出目录。" }
        return model.config.output
    }

    private func metric(_ title: String, _ value: Int, emphasize: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.title2.monospacedDigit())
                .foregroundColor(emphasize ? .red : .primary)
        }
    }
}
