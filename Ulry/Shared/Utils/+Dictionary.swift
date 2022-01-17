//
//  +Dictionary.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/16/22.
//

import Foundation

extension Dictionary {
    func findFirstValue(keys: [Key]) -> Value? {
        for key in keys {
            if let value = self[key] {
                return value
            }
        }
        
        return nil
    }
}
