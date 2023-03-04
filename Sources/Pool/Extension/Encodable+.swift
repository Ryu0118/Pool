// 
//  Encodable+.swift
//  
//
//  Created by ryunosuke.shibuya on 2023/03/04.
//

import Foundation

extension Encodable {
    var string: String? {
        get throws {
            let jsonEncoder = JSONEncoder()
            let data = try jsonEncoder.encode(self)
            let string = String(data: data, encoding: .utf8)
            return string
        }
    }
}
