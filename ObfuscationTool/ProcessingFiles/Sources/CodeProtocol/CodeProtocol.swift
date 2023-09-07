//
//  File.swift
//
//
//  Created by my on 2023/9/2.
//

import Foundation

public struct CodeOrder: Comparable {
    let order: UInt
    
    public init(order: UInt) {
        self.order = order
    }
        
    public static let topMost: CodeOrder = .init(order: 0)
    
    public static let top: CodeOrder = .init(order: 250)
    
    public static let middle: CodeOrder = .init(order: 500)
    
    public static let bottom: CodeOrder = .init(order: 750)
    
    public static let bottomMost: CodeOrder = .init(order: 1000)
    
    public static let none: CodeOrder = .middle
    
    public static func < (lhs: CodeOrder, rhs: CodeOrder) -> Bool {
        lhs.order < rhs.order
    }
}

public enum CodeType {
    case property
    case line
    case `func`
    case `import`
    case `init`
    case `deinit`
    case `subscript`
    case macro
    
    public var order: CodeOrder {
        switch self {
        case .import, .`init`: return .topMost
        case .line, .macro: return .top
        case .property: return .top
        case .subscript, .func: return .middle
        case .deinit: return .bottomMost
        }
    }
}

public enum CodeContainerType {
    case `class`
    case `struct`
    case `enum`
    case `extension`
    case `protocol`
    case block
    
    public var order: CodeOrder {
        switch self {
        case .protocol: return .topMost
        case .enum, .struct, .block: return .top
        case .class: return .middle
        case .extension: return .bottomMost
        }
    }
}

public protocol CodeRawProtocol {
    var content: String { get }
    
    var order: CodeOrder { get }
    
    var rawName: String { get }
}

public protocol CodeProtocol: CodeRawProtocol {
    var type: CodeType { get }
}

public extension CodeProtocol {
    var order: CodeOrder {
        type.order
    }
}

public protocol CodeContainerProtocol: CodeRawProtocol {
    var type: CodeContainerType { get }
    
    var entireDeclare: String { get }
        
    var code: [CodeRawProtocol] { get }
}

// MARK: -- Extensions
public extension CodeContainerProtocol {
    var order: CodeOrder {
        type.order
    }
    
    var content: String {
        String(format: "%@ {%@\n}", entireDeclare, code.map(\.content).joined())
    }
    
    func getCodeForType(_ type: CodeType) -> [CodeProtocol] {
        code.map({ $0.asCode(type) })
            .filter({ $0 != nil })
            .map({ $0! })
    }
    
    func getCodeContainerForType(_ type: CodeContainerType) -> [CodeContainerProtocol] {
        code.map({ $0.asCodeContainer(type) })
            .filter({ $0 != nil })
            .map({ $0! })
    }
}

extension CodeRawProtocol {
    public var isCode: Bool {
        self is CodeProtocol
    }
    
    public var isCodeContainer: Bool {
        self is CodeContainerProtocol
    }
    
    public func asCodeContainer(_ type: CodeContainerType) -> CodeContainerProtocol? {
        if let container = self as? CodeContainerProtocol, container.type == type {
            return container.asCodeContainer()
        }
        return nil
    }
    
    public func asCode(_ type: CodeType) -> CodeProtocol? {
        if let code = self as? CodeProtocol, code.type == type {
            return code.asCode()
        }
        return nil
    }
}
