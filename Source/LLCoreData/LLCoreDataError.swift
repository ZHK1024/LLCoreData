//
//  LLCoreDataError.swift
//  LLCoreData
//
//  Created by ZHK on 2021/7/14.
//  
//

import Foundation

struct LLCoreDataError: Error {
    
    let message: String
    
    var localizedDescription: String { message }
    
    init(_ message: String?) {
        self.message = message ?? "未知错误"
    }
}

extension LLCoreDataError: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self.message = value
    }
}

extension LLCoreDataError: LocalizedError {
    
    var errorDescription: String? {
        return message
    }
}
