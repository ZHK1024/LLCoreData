//
//  Logger.swift
//  Automation
//
//  Created by Ruris on 2025/8/14.
//

import Foundation

struct Logger {
    
    enum LogType: String {
        case info = "INFO"
        case error = "ERROR"
        case debug = "DEBUG"
    }
    
    static private var fileURL: URL? = nil
    
    /// 配置日志文件路径
    /// - Parameter path: 日志文件路径
    static func configuration(file: URL) {
        fileURL = file
    }
    
    /// 获取日志信息
    /// - Returns: 一个包含日志信息的字符串，如果没有日志信息则返回 nil
    static func info() -> String? {
        guard let fileURL else {
            return nil
        }
        return try? String(contentsOf: fileURL)
    }
    
    /// 记录日志信息
    /// - Parameters:
    ///   - type: 日志类型，默认为 `.error`
    ///   - info: 日志信息
    public static func append(_ type: LogType = .error, info: String) {
        guard let fileURL else {
            return
        }
        let log = "[\(type.rawValue)] \(Date()) \(info)\n"
        if let data = log.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }
    
    public static func info(_ message: String) {
        append(.info, info: message)
    }
    
    public static func error(_ message: String) {
        append(.error, info: message)
    }
    
    public static func debug(_ message: String) {   
        append(.debug, info: message)
    }
}

extension Logger {
    
    public static func initConfiguration() {
        if let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.zhk.charge") {
            let url = directory.appendingPathComponent("auto.text")
            Logger.configuration(file: url)
        }
    }
}
