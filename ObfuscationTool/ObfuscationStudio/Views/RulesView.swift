import SwiftUI
import ObfuscationCore

struct RulesView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Menu("添加") {
                        Button("替换") { model.ensureSingletonRule(.replace) }
                            .disabled(model.hasSingletonRule(.replace))
                        Button("大小写") { model.ensureSingletonRule(.caseConvert) }
                            .disabled(model.hasSingletonRule(.caseConvert))
                        Button("打乱结构") { model.ensureSingletonRule(.shuffle) }
                            .disabled(model.hasSingletonRule(.shuffle))
                    }
                    Button("删除") { model.deleteSelectedRule() }
                        .disabled(model.selectedRuleID == nil)
                    Spacer()
                }

                if model.config.rules.isEmpty {
                    Text("还没有规则。替换用来改前缀，大小写用来改命名风格，打乱结构只作用于 Swift。")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                } else {
                    List(selection: $model.selectedRuleID) {
                        ForEach(model.config.rules) { rule in
                            HStack {
                                Toggle("", isOn: bindingEnabled(rule.id))
                                    .labelsHidden()
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ruleTitle(rule))
                                        .lineLimit(1)
                                    Text(rule.appliesToSummary)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .tag(rule.id)
                        }
                        .onMove(perform: model.moveRules)
                    }
                }
            }
            .padding(12)
            .frame(minWidth: 240, idealWidth: 280, maxHeight: .infinity)

            Group {
                if let id = model.selectedRuleID,
                   let idx = model.config.rules.firstIndex(where: { $0.id == id })
                {
                    RuleDetailView(rule: $model.config.rules[idx])
                        .padding(20)
                } else {
                    Text("选择一条规则，或从左上角添加。")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 360, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationSubtitle("规则")
    }

    private func bindingEnabled(_ id: Rule.ID) -> Binding<Bool> {
        Binding(
            get: { model.config.rules.first(where: { $0.id == id })?.enabled ?? false },
            set: { newValue in
                guard let idx = model.config.rules.firstIndex(where: { $0.id == id }) else { return }
                model.config.rules[idx].enabled = newValue
            }
        )
    }

    private func ruleTitle(_ rule: Rule) -> String {
        switch rule.kind {
        case .replace:
            return "替换"
        case let .caseConvert(prefix, _, direction):
            let name = direction == .camelToSnake ? "驼峰 → 下划线" : "下划线 → 驼峰"
            return prefix.isEmpty ? name : "\(name) · \(prefix)"
        case .shuffle:
            return "打乱结构"
        }
    }
}

private extension Rule {
    var appliesToSummary: String {
        switch kind {
        case .shuffle:
            return "Swift 声明顺序"
        case .replace, .caseConvert:
            let path = appliesTo.contains(.path)
            let content = appliesTo.contains(.content)
            switch (path, content) {
            case (true, true): return "路径和内容"
            case (true, false): return "只改路径"
            case (false, true): return "只改内容"
            case (false, false): return "未选择作用范围"
            }
        }
    }
}

private struct RuleDetailView: View {
    @Binding var rule: Rule

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            targetsRow
                .onAppear { sanitizeTargets() }
                .onChange(of: rule.kind) { _ in sanitizeTargets() }

            Divider()

            switch rule.kind {
            case var .replace(map):
                ReplaceEditor(map: Binding(
                    get: { map },
                    set: { newMap in
                        map = newMap
                        rule.kind = .replace(map: newMap)
                    }
                ))

            case let .caseConvert(prefix, toLowercase, direction):
                VStack(alignment: .leading, spacing: 12) {
                    Picker("方向", selection: Binding(
                        get: { direction },
                        set: { rule.kind = .caseConvert(prefix: prefix, toLowercase: toLowercase, direction: $0) }
                    )) {
                        Text("驼峰 → 下划线").tag(CaseConvertDirection.camelToSnake)
                        Text("下划线 → 驼峰").tag(CaseConvertDirection.snakeToCamel)
                    }
                    .pickerStyle(.segmented)

                    TextField("前缀，例如 BF_", text: Binding(
                        get: { prefix },
                        set: { rule.kind = .caseConvert(prefix: $0, toLowercase: toLowercase, direction: direction) }
                    ))
                    Toggle("结果改为小写", isOn: Binding(
                        get: { toLowercase },
                        set: { rule.kind = .caseConvert(prefix: prefix, toLowercase: $0, direction: direction) }
                    ))
                    Text("只处理带这个前缀的名字。关闭「结果改为小写」时，会把每段首字母大写。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

            case .shuffle:
                Text("打乱 Swift 类型里声明的顺序。不改名字，也不处理 Objective-C。")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private var targetsRow: some View {
        Group {
            if isShuffleRule {
                Label("只作用于 Swift 结构", systemImage: "arrow.up.arrow.down")
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 16) {
                    Text("作用于")
                    Toggle("路径和文件名", isOn: Binding(
                        get: { rule.appliesTo.contains(.path) },
                        set: { updateTarget(.path, enabled: $0) }
                    ))
                    Toggle("文件内容", isOn: Binding(
                        get: { rule.appliesTo.contains(.content) },
                        set: { updateTarget(.content, enabled: $0) }
                    ))
                }
            }
        }
    }

    private func updateTarget(_ target: RuleTarget, enabled: Bool) {
        if isShuffleRule {
            rule.appliesTo = [.swiftStructure]
            return
        }

        if enabled {
            rule.appliesTo.insert(target)
        } else {
            rule.appliesTo.remove(target)
        }

        rule.appliesTo.remove(.swiftStructure)
    }

    private var isShuffleRule: Bool {
        if case .shuffle = rule.kind { return true }
        return false
    }

    private func sanitizeTargets() {
        if isShuffleRule {
            if case let .shuffle(orderAware) = rule.kind, orderAware != true {
                rule.kind = .shuffle(orderAware: true)
            }
            rule.appliesTo = [.swiftStructure]
            rule.scope.onlyFilename = false
            rule.scope.onlyPrefix = false
        } else if isReplaceRule {
            rule.scope.onlyFilename = false
            rule.scope.onlyPrefix = false
        } else {
            rule.appliesTo.remove(.swiftStructure)
            if rule.appliesTo.isEmpty {
                rule.appliesTo = [.path, .content]
            }
        }
    }

    private var isReplaceRule: Bool {
        if case .replace = rule.kind { return true }
        return false
    }
}

private struct ReplaceEditor: View {
    @Binding var map: [String: String]
    @State private var newKey: String = ""
    @State private var newValue: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("较长的原文会先替换。")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("原文，例如 BF_", text: $newKey)
                TextField("换成", text: $newValue)
                Button("添加") { addPair() }
                    .disabled(newKey.isEmpty)
            }

            List {
                ForEach(map.keys.sorted { $0.count > $1.count }, id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.system(.body, design: .monospaced))
                            .frame(minWidth: 80, alignment: .leading)
                        TextField("换成", text: Binding(
                            get: { map[key] ?? "" },
                            set: { map[key] = $0 }
                        ))
                        .font(.system(.body, design: .monospaced))
                        Button("删除") {
                            map.removeValue(forKey: key)
                        }
                    }
                }
            }
            .frame(minHeight: 220)
        }
    }

    private func addPair() {
        let key = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        map[key] = newValue
        newKey = ""
        newValue = ""
    }
}
