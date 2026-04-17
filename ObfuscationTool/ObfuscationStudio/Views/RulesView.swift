import SwiftUI
import ObfuscationCore

struct RulesView: View {
    @EnvironmentObject private var model: StudioModel

    var body: some View {
        NavigationSplitView {
            List(selection: $model.selectedRuleID) {
                ForEach(model.config.rules) { rule in
                    HStack {
                        Toggle("", isOn: bindingEnabled(rule.id))
                            .labelsHidden()
                        Text(ruleTitle(rule))
                            .lineLimit(1)
                    }
                    .tag(rule.id)
                }
                .onMove(perform: model.moveRules)
            }
            .toolbar {
                Button("添加 Replace") {
                    model.ensureSingletonRule(.replace)
                }
                .disabled(model.hasSingletonRule(.replace))
                Button("添加 CaseConvert") {
                    model.ensureSingletonRule(.caseConvert)
                }
                .disabled(model.hasSingletonRule(.caseConvert))
                Button("添加 Shuffle") {
                    model.ensureSingletonRule(.shuffle)
                }
                .disabled(model.hasSingletonRule(.shuffle))
                Button("删除") { model.deleteSelectedRule() }
                    .disabled(model.selectedRuleID == nil)
            }
        } detail: {
            if let id = model.selectedRuleID,
               let idx = model.config.rules.firstIndex(where: { $0.id == id })
            {
                RuleDetailView(rule: $model.config.rules[idx])
                    .padding()
            } else {
                Text("选择一条规则进行编辑")
                    .foregroundColor(.secondary)
            }
        }
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
            return "Replace"
        case let .caseConvert(prefix, _, direction):
            return "CaseConvert(\(direction.rawValue)) \(prefix)"
        case .shuffle:
            return "Shuffle"
        }
    }
}

private struct RuleDetailView: View {
    @Binding var rule: Rule

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("作用范围")
                Spacer()
                targetsRow
            }
            .onAppear { sanitizeTargets() }
            .onChange(of: rule.kind) { _ in sanitizeTargets() }

            if supportsOnlyPrefix {
                Toggle("onlyPrefix", isOn: $rule.scope.onlyPrefix)
            }

            if supportsOnlyFilename {
                Toggle("onlyFilename", isOn: $rule.scope.onlyFilename)
            }

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
                VStack(alignment: .leading) {
                    Picker("direction", selection: Binding(
                        get: { direction },
                        set: { rule.kind = .caseConvert(prefix: prefix, toLowercase: toLowercase, direction: $0) }
                    )) {
                        ForEach(CaseConvertDirection.allCases, id: \.self) { dir in
                            Text(dir.rawValue).tag(dir)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("prefix", text: Binding(
                        get: { prefix },
                        set: { rule.kind = .caseConvert(prefix: $0, toLowercase: toLowercase, direction: direction) }
                    ))
                    Toggle("toLowercase", isOn: Binding(
                        get: { toLowercase },
                        set: { rule.kind = .caseConvert(prefix: prefix, toLowercase: $0, direction: direction) }
                    ))
                }

            case .shuffle:
                Text("Shuffle = Swift 结构重排（仅对 Swift 文件内容生效）")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var supportsOnlyPrefix: Bool {
        return false
    }

    private var supportsOnlyFilename: Bool {
        false
    }

    private var targetsRow: some View {
        Group {
            if isShuffleRule {
                Text("Swift 结构重排")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 12) {
                    Toggle("文件名/路径", isOn: Binding(
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
            HStack {
                TextField("origin", text: $newKey)
                TextField("replace", text: $newValue)
                Button("添加") {
                    guard !newKey.isEmpty else { return }
                    map[newKey] = newValue
                    newKey = ""
                    newValue = ""
                }
            }

            List {
                ForEach(map.keys.sorted { $0.count > $1.count }, id: \.self) { key in
                    HStack {
                        Text(key).font(.system(.body, design: .monospaced))
                        Spacer()
                        Text(map[key] ?? "")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        Button("删除") {
                            map.removeValue(forKey: key)
                        }
                    }
                }
            }
            .frame(minHeight: 200)
        }
    }
}

