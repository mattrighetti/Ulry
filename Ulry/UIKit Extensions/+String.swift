//
//  +String.swift
//  Ulry
//
//  Created by Matt on 16/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

extension String {
    var nilIfEmpty: String? {
        if self.isEmpty {
            return nil
        } else {
            return self
        }
    }
}
