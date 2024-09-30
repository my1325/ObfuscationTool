//
//  TemplateType.swift
//  Command
//
//  Created by mayong on 2023/9/27.
//

import Foundation
import PathKit

struct TemplateType {
    let filePath: Path

    init(_ path: Path) {
        filePath = path
    }

    static var yamlLiveTemplate: String {
        """
        #path: BF_LiveKitSwift/
        replace:
            only_prefix: true
            map:
                BF_: FB_
                bf_: fb_
        shuffule:
            order: true
        zips:
           -
            name: resources.zip
            password: 123456
           -
            name: resources.zip
            new_password: 123456
        output: ObfuscationCode/
        """
    }
}
