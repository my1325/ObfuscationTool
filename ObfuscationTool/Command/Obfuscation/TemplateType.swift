//
//  TemplateType.swift
//  Command
//
//  Created by mayong on 2023/9/27.
//

import Foundation

enum TemplateType {
    case live
    case mulitbeam
    case dynamic
    
    init(rawValue: String) throws {
        switch rawValue {
        case "live": self = .live
        case "mulitbeam": self = .mulitbeam
        case "dynamic": self = .dynamic
        default: throw ObfuscationError.unknownTemplateError(rawValue)
        }
    }
    
    var yamlLiveTemplate: String {
    """
    git:
        url: http://gitlab.wudi360.com/liqinglian/livekitswift.git
        tag: 1.1.0
    #    branch: dev
    #path: BF_LiveKitSwift/
    replace:
        map:
            BF_: FB_
            bf_: fb_
        handle_file: true
    #prefix:
        #prefix: bf
        #separator: -
        #handle_file: true
        #should_add: false
    shuffule:
        order: true
    images:
        compress: 1
        md5: true
    output: ObfuscationCode/
    """
    }
    
    var template: String {
        switch self {
        case .live: return yamlLiveTemplate
        case .mulitbeam: return ""
        case .dynamic: return ""
        }
    }
    
    var name: String {
        switch self {
        case .live: return "live"
        case .mulitbeam: return "mulitbeam"
        case .dynamic: return "dynamic"
        }
    }
}
