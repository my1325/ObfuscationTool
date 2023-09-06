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
    case macro
    
    public var order: CodeOrder {
        switch self {
        case .import: return .topMost
        case .line, .macro: return .top
        case .property: return .top
        case .func: return .middle
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

public extension CodeContainerProtocol {
    var order: CodeOrder {
        type.order
    }
    
    var content: String {
        String(format: "%@ {%@\n}", entireDeclare, code.map(\.content).joined())
    }
}

extension CodeRawProtocol {
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
