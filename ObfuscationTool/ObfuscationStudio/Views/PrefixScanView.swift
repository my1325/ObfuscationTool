import SwiftUI
import ObfuscationCore

struct PrefixScanView: View {
    @EnvironmentObject private var model: StudioModel
    @State private var showEmptyGroups = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if model.prefixScanIsRunning {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在扫描 Swift 标识符…")
                        .foregroundColor(.secondary)
                } else {
                    Button("重新扫描") { model.scanPrefixes() }
                        .disabled(model.config.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Spacer()
                Text(model.config.input.isEmpty ? "还没有源目录" : model.config.input)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if let err = model.prefixScanError {
                Text(err).foregroundColor(.red)
            }

            if let result = model.prefixScanResult {
                summary(result)
                Toggle("显示没有命中的种类", isOn: $showEmptyGroups)
                    .toggleStyle(.checkbox)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Self.sections, id: \.kind) { section in
                            let hits = result.hitsByKind[section.kind] ?? []
                            if showEmptyGroups || !hits.isEmpty {
                                PrefixSection(title: section.title, hits: hits)
                            }
                        }
                    }
                }
            } else if !model.prefixScanIsRunning {
                Text("扫描源目录里带下划线的 Swift 前缀，例如 BF_、bf_。已经写进规则的前缀会当成官方前缀，不再列出来。")
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .navigationSubtitle("前缀")
        .onAppear { model.scanPrefixes() }
    }

    private func summary(_ result: PrefixScanResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("未覆盖 \(model.uncoveredPrefixCount) 个 · 官方 \(result.officialPrefixes.count) 个")
                .font(.headline)
            if result.officialPrefixes.isEmpty {
                Text("当前规则里还没有官方前缀。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("官方：\(result.officialPrefixes.sorted().joined(separator: "  "))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }

    private static let sections: [(kind: PrefixSymbolKind, title: String)] = [
        (.typeClass, "类"),
        (.typeStruct, "结构体"),
        (.typeEnum, "枚举"),
        (.typeProtocol, "协议"),
        (.typeActor, "Actor"),
        (.function, "方法"),
        (.variable, "变量"),
    ]
}

private struct PrefixSection: View {
    @EnvironmentObject private var model: StudioModel
    let title: String
    let hits: [PrefixHit]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            if hits.isEmpty {
                Text("无").foregroundColor(.secondary)
            } else {
                ForEach(hits, id: \.self) { hit in
                    HStack(alignment: .firstTextBaseline) {
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(hit.samples, id: \.self) { sample in
                                    Text(sample).font(.system(.body, design: .monospaced))
                                }
                            }
                            .padding(.top, 4)
                        } label: {
                            HStack {
                                Text(hit.prefix).font(.system(.body, design: .monospaced))
                                Text("\(hit.count)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        if model.replacementAlreadyHas(hit.prefix) {
                            Text("已在规则中")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Button("加入规则") { model.adoptPrefix(hit.prefix) }
                                .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
    }
}
