//
//  File.swift
//  
//
//  Created by my on 2023/9/2.
//

import Foundation
import FilePath

public enum ProcessingError: Error {
    case fileReadError(PathProtocol)
    case notPluginForFileType(FileType)
    case underlying(Error)
}
