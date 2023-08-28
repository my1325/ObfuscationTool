//
//  File.swift
//  
//
//  Created by mayong on 2023/8/28.
//

import Foundation
import ProcessingFiles
import FilePath
import SwiftString

struct SwiftProcessingFile: ProcessingFile {
    let lines: [ProcessingLine]
}

struct SwiftProcessingLine: ProcessingLine {
    let rawValue: String
    let output: String
    let identifier: ProcessingIdentifier
}

open class SwiftFilePlugin: ProcessingFilePlugin {
    
    public func processingManager(_ manager: ProcessingManager, processedFile file: FilePath) async -> ProcessingFile {
        let lines = await linesForFile(file)
        return SwiftProcessingFile(lines: lines)
    }
    
    public func linesForFile(_ file: FilePath) async -> [ProcessingLine] {
        do {
            var lines: [ProcessingLine] = []
            var temp: [ProcessingLine] = []
            for lineString in try file.fileIterator() {
                let string = prehandleLineString(lineString)
                guard string.count > .zero else { continue }
                


                
                if condition {
                    lines.append(contentsOf: temp)
                    temp.removeAll()
                }
            }
            return lines
        } catch {
            debugPrint(error)
            return []
        }
    }
    
    private func prehandleLineString(_ lineString: String) -> [SwiftString] {
        /// 把行中的字符串用STRING标识符代替， 把注释提出来
        /// """ 前面如果有code，"""另外起一行
        /// """; code 去掉分号，后面的code另外起一行
        /// 
    }
}
