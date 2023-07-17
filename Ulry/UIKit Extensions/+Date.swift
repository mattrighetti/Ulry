//
//  +Date.swift
//  Ulry
//
//  Created by Mattia Righetti on 17/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import Foundation

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}
