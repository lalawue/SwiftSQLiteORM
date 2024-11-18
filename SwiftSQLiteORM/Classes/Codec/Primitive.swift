//
//  Primitive.swift
//  AnyCoder
//
//  Created by Valo on 2020/11/20.
//

import Foundation

// only keep some used extension by lalawue

extension String {
    init(bytes: [UInt8]) {
        self = String(bytes: bytes, encoding: .utf8) ?? String(bytes: bytes, encoding: .ascii) ?? ""
    }

    var bytes: [UInt8] { utf8.map { UInt8($0) }}
}

extension Data {
    var bytes: [UInt8] { [UInt8](self) }
}

extension Array {
    func splat(_ num: Int) -> Any? {
        guard num > 0, num <= count, num <= 10 else { return nil }
        switch num {
        case 1: return (self[0])
        case 2: return (self[0], self[1])
        case 3: return (self[0], self[1], self[2])
        case 4: return (self[0], self[1], self[2], self[3])
        case 5: return (self[0], self[1], self[2], self[3], self[4])
        case 6: return (self[0], self[1], self[2], self[3], self[4], self[5])
        case 7: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6])
        case 8: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7])
        case 9: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7], self[8])
        case 10: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7], self[8], self[9])
            
        case 11: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7], self[8], self[9],
                         self[10])
        case 12: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7], self[8], self[9],
                         self[10], self[11])
        case 13: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7], self[8], self[9],
                         self[10], self[11], self[12])
        case 14: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7], self[8], self[9],
                         self[10], self[11], self[12], self[13])
        case 15: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7], self[8], self[9],
                         self[10], self[11], self[12], self[13], self[14])
        case 16: return (self[0], self[1], self[2], self[3], self[4], self[5], self[6], self[7], self[8], self[9],
                         self[10], self[11], self[12], self[13], self[14], self[15])
            
        default: return nil
        }
    }
}
