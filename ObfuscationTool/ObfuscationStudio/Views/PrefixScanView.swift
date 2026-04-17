import SwiftUI
import ObfuscationCore

struct PrefixScanView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if model.prefixScanIsRunning {
                    Text("扫描中…")
                        .foregroundColor(.secondary)
                } else {
                    Button("重新扫描") {
                        model.scanPrefixes()
                    }
                }

                Spacer()
                Text(model.config.input.isEmpty ? "input 未选择" : model.config.input)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if let err = model.prefixScanError {
                Text(err).foregroundColor(.red)
            }

            if let result = model.prefixScanResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PrefixSection(title: "类 (class)", hits: result.hitsByKind[.typeClass] ?? [])
                        PrefixSection(title: "结构体 (struct)", hits: result.hitsByKind[.typeStruct] ?? [])
                        PrefixSection(title: "枚举 (enum)", hits: result.hitsByKind[.typeEnum] ?? [])
                        PrefixSection(title: "协议 (protocol)", hits: result.hitsByKind[.typeProtocol] ?? [])
                        PrefixSection(title: "Actor", hits: result.hitsByKind[.typeActor] ?? [])
                        PrefixSection(title: "方法 (func)", hits: result.hitsByKind[.function] ?? [])
                        PrefixSection(title: "变量 (var/let)", hits: result.hitsByKind[.variable] ?? [])
                    }
                }
            } else {
                Text("会扫描 Swift 源码里标识符的 underscore 前缀（如 BF_ / bf_），并过滤掉已在当前规则里配置过的“官方前缀”。")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            model.scanPrefixes()
        }
    }
}

private struct PrefixSection: View {
    let title: String
    let hits: [PrefixHit]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            if hits.isEmpty {
                Text("无").foregroundColor(.secondary)
            } else {
                ForEach(hits, id: \.self) { hit in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(hit.samples, id: \.self) { s in
                                Text(s).font(.system(.body, design: .monospaced))
                            }
                        }
                        .padding(.top, 4)
                    } label: {
                        HStack {
                            Text(hit.prefix).font(.system(.body, design: .monospaced))
                            Spacer()
                            Text("\(hit.count)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

