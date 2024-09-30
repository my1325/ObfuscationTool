//
//  File.swift
//  
//
//  Created by my on 2023/9/2.
//

import Foundation
import PathKit

public enum ProcessingError: Error {
    case fileReadError(Path)
    case notPluginForFileType(FileType)
    case underlying(Error)
}
