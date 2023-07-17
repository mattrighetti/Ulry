//
//  +Set.swift
//  Ulry
//
//  Created by Mattia Righetti on 11/5/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

extension Set {
    public mutating func toggle(_ element: Element) {
        if self.contains(element) {
            self.remove(element)
        } else {
            self.insert(element)
        }
    }
}
