//
//  RegisterInitialValuesForUserDefaultsStartupTask.swift
//  Ulry
//
//  Created by Matt on 16/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

struct RegisterInitialValuesForUserDefaultsStartupTask: StartupTask {
    var runOnce: Bool = false
    var key: String = "RegisterInitialValuesForUserDefaultsStartupTask"

    func execTask() throws {
        UserDefaultsWrapper().registerDefaults()
    }
}
