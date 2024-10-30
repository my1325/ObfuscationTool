//
//  AssetsTool.swift
//  Command
//
//  Created by mayong on 2024/10/8.
//

import Foundation
import PathKit

open class AssetsTool {
    let assetsPath: Path
    init(_ assetsPath: Path) {
        self.assetsPath = assetsPath
    }
    
    func resolve(_ resolver: (String) -> String) throws {
        
    }
}
