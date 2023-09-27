//
//  Obfuscation.swift
//  Command
//
//  Created by mayong on 2023/9/27.
//

import Foundation
import SwiftGit2
import FilePath

internal final class Obfuscation {
    let config: ObfuscationConfig
    init(config: ObfuscationConfig) {
        self.config = config
    }
    
    var git: ObfuscationGit { config.git }
    
    var path: String { config.path }
    
    var shouldHandleImage: Bool { config.images.enable }
    
    var shouldHandlePrefix: Bool { config.replace.enable }
    
    var shouldShuffule: Bool { config.shuffule.enable }
    
    func run() {
        
    }
    
    private func checkGit() {
        let current = DirectoryPath.current.appendConponent("")
    }
    
    private func checkPath() {
        
    }
}
