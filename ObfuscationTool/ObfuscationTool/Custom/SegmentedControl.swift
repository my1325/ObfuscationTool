////
////  OB_SegmentedControl.swift
////  ObfuscationTool
////
////  Created by mayong on 2023/9/8.
////
//
//import Cocoa
//import SnapKit
//import Combine
//
//internal final class SegmentedTitleItem: NSView {
//    private lazy var titleLabel: NSTextField = {
//        $0.translatesAutoresizingMaskIntoConstraints = false
//        $0.font = NSFont.systemFont(ofSize: 14)
//        $0.alignment = .center
//        self.addSubview($0)
//        $0.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        return $0
//    }(NSTextField(labelWithString: ""))
//
//    private lazy var touchButton: NSButton = {
//        $0.translatesAutoresizingMaskIntoConstraints = false
//        $0.isBordered = false
//        self.addSubview($0)
//        $0.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        return $0
//    }(NSButton(title: "", target: self, action: #selector(touchAction)))
//
//    @objc private func touchAction() {
//        action()
//    }
//
//    override func viewWillMove(toSuperview newSuperview: NSView?) {
//        super.viewWillMove(toSuperview: newSuperview)
//        _ = titleLabel
//        _ = touchButton
//    }
//
//    var string: String = "" {
//        didSet {
//            titleLabel.stringValue = string
//        }
//    }
//
//    let action: () -> Void
//    init(action: @escaping () -> Void) {
//        self.action = action
//        super.init(frame: .zero)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//internal final class SegmentedControl: NSView {
//
//    private lazy var stackView: NSStackView = {
//        $0.translatesAutoresizingMaskIntoConstraints = false
//        $0.alignment = .centerY
//        $0.distribution = .fillEqually
//        self.addSubview($0)
//        $0.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        return $0
//    }(NSStackView(views: []))
//
//    @Published
//    var selectedIndex: Int = 0
//
//    var items: [String] = [] {
//        didSet {
//            stackView.views.forEach({
//                stackView.removeArrangedSubview($0)
//                $0.removeFromSuperview()
//            })
//
//            for index in 0 ..< items.count {
//                let item = stringItemView(items[index], index: index)
//                stackView.addArrangedSubview(item)
//            }
//        }
//    }
//
//    private func stringItemView(_ string: String, index: Int) -> SegmentedTitleItem {
//        let item = SegmentedTitleItem(action: { [weak self] in
//            self?.selectedIndex = index
//        })
//        item.string = string
//        return item
//    }
//}
