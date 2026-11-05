import Foundation
import SwiftUI
import UniformTypeIdentifiers
import ObfuscationCore
import PathKit
import Combine

enum SidebarSelection: Hashable {
    case config
    case rules
    case prefixScan
    case preview
    case run
}

@MainActor
final class StudioModel: ObservableObject {
    @Published var sidebarSelection: SidebarSelection = .config

    @Published var config: ProjectConfig = .init(input: "", output: "", keepDirectory: false, rules: [])
    @Published var selectedRuleID: Rule.ID?

    @Published var previewFilePath: String = ""
    @Published var previewBefore: String = ""
    @Published var previewAfter: String = ""
    @Published var previewError: String?

    @Published var prefixScanIsRunning: Bool = false
    @Published var prefixScanError: String?
    @Published var prefixScanResult: PrefixScanResult?

    @Published var isRunning: Bool = false
    @Published var progressText: String = ""
    @Published var logLines: [String] = []
    @Published var lastRunSummary: RunSummary?
    @Published var bannerMessage: String?
    @Published var configURL: URL?

    private var cancellationToken: CancellationToken?
    private var prefixScanTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    var windowTitle: String {
        let name = (config.input as NSString).lastPathComponent
        return name.isEmpty ? "混淆" : "混淆 · \(name)"
    }

    var uncoveredPrefixCount: Int {
        guard let result = prefixScanResult else { return 0 }
        var seen = Set<String>()
        for hits in result.hitsByKind.values {
            for hit in hits where hit.count > 0 {
                seen.insert(hit.prefix)
            }
        }
        return seen.count
    }

    func replacementAlreadyHas(_ prefix: String) -> Bool {
        config.rules.contains { rule in
            guard case let .replace(map) = rule.kind else { return false }
            return map[prefix] != nil
        }
    }

    init() {
        $config
            .map(\.input)
            .removeDuplicates()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.schedulePrefixScan(force: true)
            }
            .store(in: &cancellables)

        $sidebarSelection
            .removeDuplicates()
            .sink { [weak self] sel in
                guard sel == .prefixScan else { return }
                self?.schedulePrefixScan(force: true)
            }
            .store(in: &cancellables)
    }

    func newConfig() {
        config = .init(input: "", output: "", keepDirectory: false, rules: [])
        selectedRuleID = nil
        previewFilePath = ""
        previewBefore = ""
        previewAfter = ""
        previewError = nil
        prefixScanIsRunning = false
        prefixScanError = nil
        prefixScanResult = nil
        logLines = []
        progressText = ""
        lastRunSummary = nil
        bannerMessage = nil
        configURL = nil
        sidebarSelection = .config
    }

    /// 把扫描到的前缀放进唯一的替换规则。已有的替换结果不覆盖。
    func adoptPrefix(_ prefix: String) {
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ensureSingletonRule(.replace)
        guard let idx = config.rules.firstIndex(where: {
            if case .replace = $0.kind { return true }
            return false
        }) else { return }
        guard case var .replace(map) = config.rules[idx].kind else { return }
        if map[trimmed] != nil {
            bannerMessage = "\(trimmed) 已在替换规则里"
        } else {
            map[trimmed] = ""
            config.rules[idx].kind = .replace(map: map)
            bannerMessage = "已加入 \(trimmed)，请填写要换成的前缀"
        }
        selectedRuleID = config.rules[idx].id
        sidebarSelection = .rules
    }

    func presentOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json]
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            DispatchQueue.main.async {
                self?.loadConfig(from: url)
            }
        }
    }

    func saveConfigInteractively() {
        if let configURL {
            saveConfig(to: configURL)
        } else {
            presentSavePanel()
        }
    }

    func presentSavePanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = configURL?.lastPathComponent ?? "obfuscation.json"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            DispatchQueue.main.async {
                self?.saveConfig(to: url)
            }
        }
    }

    func scanPrefixes() {
        schedulePrefixScan(force: true)
    }

    private func schedulePrefixScan(force: Bool = false) {
        let input = config.input.trimmingCharacters(in: .whitespacesAndNewlines)
        if input.isEmpty {
            prefixScanTask?.cancel()
            prefixScanIsRunning = false
            prefixScanResult = nil
            prefixScanError = nil
            return
        }

        if !force, sidebarSelection != .prefixScan, prefixScanResult != nil {
            return
        }

        prefixScanTask?.cancel()
        let rules = config.rules
        let root = PathKit.Path(input)

        prefixScanError = nil
        prefixScanIsRunning = true

        prefixScanTask = Task.detached(priority: .userInitiated) {
            let scanner = PrefixScanner()
            let result = scanner.scan(inputRoot: root, rules: rules)
            await MainActor.run {
                self.prefixScanResult = result
                self.prefixScanIsRunning = false
            }
        }
    }

    func addRule(_ rule: Rule) {
        config.rules.append(rule)
        selectedRuleID = rule.id
    }

    enum SingletonRuleType {
        case replace
        case caseConvert
        case shuffle
    }

    func ensureSingletonRule(_ type: SingletonRuleType) {
        if let existing = config.rules.first(where: { matchesSingletonType($0, type: type) }) {
            selectedRuleID = existing.id
            return
        }

        switch type {
        case .replace:
            addRule(
                .init(
                    appliesTo: [.path, .content],
                    scope: .init(onlyPrefix: false, onlyFilename: false),
                    kind: .replace(map: [:])
                )
            )
        case .caseConvert:
            addRule(
                .init(
                    appliesTo: [.path, .content],
                    kind: .caseConvert(prefix: "", toLowercase: true, direction: .camelToSnake)
                )
            )
        case .shuffle:
            addRule(
                .init(
                    appliesTo: [.swiftStructure],
                    kind: .shuffle(orderAware: true)
                )
            )
        }
    }

    func removeDuplicateSingletonRules() {
        var seen: Set<SingletonRuleType> = []
        var unique: [Rule] = []

        for rule in config.rules {
            if let t = singletonType(for: rule) {
                if seen.contains(t) { continue }
                seen.insert(t)
            }
            unique.append(rule)
        }
        config.rules = unique
        if selectedRuleID != nil, !config.rules.contains(where: { $0.id == selectedRuleID }) {
            selectedRuleID = config.rules.first?.id
        }
    }

    func hasSingletonRule(_ type: SingletonRuleType) -> Bool {
        config.rules.contains(where: { matchesSingletonType($0, type: type) })
    }

    private func matchesSingletonType(_ rule: Rule, type: SingletonRuleType) -> Bool {
        singletonType(for: rule) == type
    }

    private func singletonType(for rule: Rule) -> SingletonRuleType? {
        switch rule.kind {
        case .replace: return .replace
        case .caseConvert: return .caseConvert
        case .shuffle: return .shuffle
        }
    }

    func deleteSelectedRule() {
        guard let id = selectedRuleID else { return }
        config.rules.removeAll { $0.id == id }
        selectedRuleID = config.rules.first?.id
    }

    func moveRules(fromOffsets: IndexSet, toOffset: Int) {
        config.rules.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    func loadConfig(from url: URL) {
        do {
            config = try ConfigIO.load(from: url)
            removeDuplicateSingletonRules()
            selectedRuleID = config.rules.first?.id
            configURL = url
            bannerMessage = "已打开 \(url.lastPathComponent)"
        } catch {
            bannerMessage = "打开失败：\(error)"
        }
    }

    func saveConfig(to url: URL) {
        do {
            try ConfigIO.save(config, to: url)
            configURL = url
            bannerMessage = "已保存 \(url.lastPathComponent)"
        } catch {
            bannerMessage = "保存失败：\(error)"
        }
    }

    func refreshPreview() {
        previewError = nil
        previewBefore = ""
        previewAfter = ""

        guard !previewFilePath.isEmpty else { return }
        let url = URL(fileURLWithPath: previewFilePath)
        do {
            let data = try Data(contentsOf: url)
            previewBefore = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            let processor = ContentProcessor()
            let out = try processor.process(path: .init(previewFilePath), data: data, rules: config.rules)
            previewAfter = String(data: out, encoding: .utf8) ?? "<non-utf8>"
        } catch {
            previewError = "\(error)"
        }
    }

    func runBatch() {
        guard !isRunning else { return }
        isRunning = true
        logLines = []
        progressText = ""
        lastRunSummary = nil
        bannerMessage = nil

        let token = CancellationToken()
        cancellationToken = token

        let runner = Runner()
        let cfg = config
        Task.detached(priority: .userInitiated) {
            runner.run(config: cfg, token: token) { event in
                Task { @MainActor in
                    self.handle(event)
                }
            }
            await MainActor.run {
                self.isRunning = false
                self.cancellationToken = nil
            }
        }
    }

    func cancelRun() {
        cancellationToken?.cancel()
    }

    private func handle(_ event: RunnerEvent) {
        switch event {
        case let .willStart(totalFiles):
            progressText = "0 / \(totalFiles)"
            logLines.append("Start: total \(totalFiles)")
        case let .willProcess(path, index, total):
            progressText = "\(index) / \(total)"
            logLines.append("Process: \(path)")
        case let .didWrite(path):
            logLines.append("Write: \(path)")
        case let .log(message):
            logLines.append(message)
        case let .didFail(path, message):
            logLines.append("Fail: \(path) - \(message)")
        case let .didFinish(summary):
            lastRunSummary = summary
            logLines.append("Finish: processed=\(summary.processedFiles) written=\(summary.writtenFiles) errors=\(summary.errors)")
        }
    }

}

