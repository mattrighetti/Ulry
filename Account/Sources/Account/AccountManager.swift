//
//  File.swift
//  
//
//  Created by Matt on 15/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

public final class AccountManager {
    public static var shared: AccountManager!
    
    private let accountsFolder: String
    private var accountsDictionary = [String:Account]()

    public var activeAccounts: [Account] {
        precondition(Thread.isMainThread)
        return Array(accountsDictionary.values.filter { $0.isActive })
    }

    public var accounts: [Account] {
        Array(accountsDictionary.values)
    }

    public init(accountsFolder: String) {
        self.accountsFolder = accountsFolder
    }
}
