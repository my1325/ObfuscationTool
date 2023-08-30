//
//  File.swift
//  
//
//  Created by mayong on 2023/8/29.
//

import Foundation

struct SwiftFilePatterns: Hashable {
    let pattern: String
    let identifier: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    static let patternFunc = SwiftFilePatterns(pattern: "(@\\w+( |\\n)+)?((public|private|fileprivate|open|internal)( |\\n)+)?(override( |\\n)+)?((class|static)( |\\n)+)?func", identifier: "SWIF_FILE_IDENTIFIER_FUNC")
    
    static let patternProperty = SwiftFilePatterns(pattern: "(@\\w+( |\\n)+)?((public|private|fileprivate|open|internal)( |\\n)+)?(override( |\\n)+)?((class|static)( |\\n)+)?(var|let)", identifier: "SWIF_FILE_IDENTIFIER_PROP")
    
    static let patternClass = SwiftFilePatterns(pattern: "(@\\w+( |\\n)+)?((public|private|fileprivate|open|internal)( |\\n)+)?(final( |\\n)+)?(class|extension|struct|enum|protocol)", identifier: "SWIF_FILE_IDENTIFIER_CLASS")
    
    static let patternString = SwiftFilePatterns(pattern: "\".*\"", identifier: "SWIF_FILE_IDENTIFIER_STRING")
    
    static let patternMultiString = SwiftFilePatterns(pattern: "\"\"\"([\\s\\S]*).*\"\"\"", identifier: "SWIF_FILE_IDENTIFIER_MULTISTRING")
    
    static let patternDocumentInline = SwiftFilePatterns(pattern: "//.*", identifier: "SWIF_FILE_IDENTIFIER_DOCUMENT_INLINE")
    
    static let patternDocumentBlock = SwiftFilePatterns(pattern: "/\\*([\\s\\S]*).*\\*/", identifier: "SWIF_FILE_IDENTIFIER_DOCUMENT_BLOCK")
    
    static let patternImport = SwiftFilePatterns(pattern: "import +\\w+", identifier: "SWIF_FILE_IDENTIFIER_IMPORT")
    
    static let patternMacroIf = SwiftFilePatterns(pattern: "#if", identifier: "SWIF_FILE_IDENTIFIER_MACRO_IF")
    
    static let patternMacroWraning = SwiftFilePatterns(pattern: "#warning", identifier: "SWIF_FILE_IDENTIFIER_MACRO_WARNING")
    
    static let patternMacroError = SwiftFilePatterns(pattern: "#error", identifier: "SWIF_FILE_IDENTIFIER_MACRO_ERROR")
}


