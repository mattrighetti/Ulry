//
//  Representable.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/10/22.
//

import Foundation

public protocol Representable: Identifiable, Hashable {
    var name: String { get }
}
