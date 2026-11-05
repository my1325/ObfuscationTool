//
//  File.swift
//  
//
//  Created by mayong on 2023/8/18.
//

import Foundation

public class FileIterator: Sequence, IteratorProtocol {
    public typealias Element = String
    
    let encoding: String.Encoding
    let chunkSize: Int
    let fileHandle: FileHandle
    let delimPattern: Data
    var buffer: Data
    var readOffset: Int = 0
    var isAtEOF: Bool = false
    
    init(url: URL, delimeter: String = "\n", encoding: String.Encoding = .utf8, chunkSize: Int = 4096) throws
    {
        fileHandle = try FileHandle(forReadingFrom: url)
        self.chunkSize = chunkSize
        self.encoding = encoding
        buffer = Data(capacity: chunkSize)
        delimPattern = delimeter.data(using: .utf8)!
    }
    
    deinit {
        fileHandle.closeFile()
    }
    
    public func makeIterator() -> FileIterator {
        fileHandle.seek(toFileOffset: 0)
        buffer.removeAll(keepingCapacity: true)
        readOffset = 0
        isAtEOF = false
        return self
    }
    
    public func next() -> Element? {
        while true {
            if readOffset < buffer.count,
               let range = buffer.range(of: delimPattern, options: [], in: readOffset..<buffer.endIndex) {
                let line = String(data: buffer.subdata(in: readOffset..<range.lowerBound), encoding: encoding)
                readOffset = range.upperBound
                compactIfNeeded()
                return line
            }
            if isAtEOF {
                guard readOffset < buffer.count else { return nil }
                let line = String(data: buffer.subdata(in: readOffset..<buffer.endIndex), encoding: encoding)
                readOffset = buffer.count
                return line
            }
            let tempData = fileHandle.readData(ofLength: chunkSize)
            if tempData.isEmpty {
                isAtEOF = true
                continue
            }
            buffer.append(tempData)
        }
    }

    /// 每读满一块再丢掉已消费的前缀，而不是每行都把剩余缓冲往前挪。
    private func compactIfNeeded() {
        guard readOffset >= chunkSize else { return }
        buffer.removeSubrange(0..<readOffset)
        readOffset = 0
    }
}
 
