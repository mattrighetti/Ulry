//
//  OrderBy.swift
//  Ulry
//
//  Created by Mattia Righetti on 7/6/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

public enum OrderBy: String {
    case name
    case lastUpdated
    case oldest
    case newest

    var orderByClause: (String, String) {
        switch self {
            case .name:
                return ("ogTitle", "asc")
            case .lastUpdated:
                return ("updated_at", "desc")
            case .oldest:
                return ("created_at", "asc")
            case .newest:
                return ("created_at", "desc")
        }
    }
}
