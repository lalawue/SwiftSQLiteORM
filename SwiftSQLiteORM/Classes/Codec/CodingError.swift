//
//  CodingError.swift
//  AnyCoder
//
//  Created by Valo on 2020/7/31.
//

import Foundation

extension EncodingError {
    static func invalidType(type: Any.Type, _ underlyingError: Error? = nil) -> Self {
        let context = EncodingError.Context(codingPath: [], debugDescription: "invalid type.", underlyingError: underlyingError)
        return EncodingError.invalidValue(type, context)
    }
}

extension DecodingError {
    static func mismatch(_ type: Any.Type, _ underlyingError: Error? = nil) -> Self {
        let context = DecodingError.Context(codingPath: [], debugDescription: "invalid type.", underlyingError: underlyingError)
        return DecodingError.typeMismatch(type, context)
    }
}
